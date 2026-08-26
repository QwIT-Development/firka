package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

func randomToken() string {
	b := make([]byte, 24)
	rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

func base64URL(v any) string {
	b, _ := json.Marshal(v)
	return base64.RawURLEncoding.EncodeToString(b)
}

func buildIdToken(instituteCode, userId, username string) string {
	header := map[string]string{"alg": "none", "typ": "JWT"}
	payload := map[string]any{
		"kreta:institute_code":    instituteCode,
		"kreta:institute_user_id": userId,
		"kreta:user_name":         username,
		"iat":                     time.Now().Unix(),
	}
	sig := make([]byte, 16)
	rand.Read(sig)
	return base64URL(header) + "." + base64URL(payload) + "." + base64.RawURLEncoding.EncodeToString(sig)
}

type sessionInfo struct {
	instituteCode string
	userId        string
	username      string
}

type AuthStore struct {
	mu            sync.Mutex
	pendingCodes  map[string]bool
	accessTokens  map[string]sessionInfo
	refreshTokens map[string]sessionInfo
}

func NewAuthStore() *AuthStore {
	return &AuthStore{
		pendingCodes:  map[string]bool{},
		accessTokens:  map[string]sessionInfo{},
		refreshTokens: map[string]sessionInfo{},
	}
}

func (a *AuthStore) issueCode() string {
	a.mu.Lock()
	defer a.mu.Unlock()
	code := randomToken()
	a.pendingCodes[code] = true
	return code
}

func (a *AuthStore) consumeCode(code string) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	if !a.pendingCodes[code] {
		return false
	}
	delete(a.pendingCodes, code)
	return true
}

func (a *AuthStore) issueTokens(info sessionInfo) (string, string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	access := randomToken()
	refresh := randomToken()
	a.accessTokens[access] = info
	a.refreshTokens[refresh] = info
	return access, refresh
}

func (a *AuthStore) consumeRefresh(token string) (sessionInfo, bool) {
	a.mu.Lock()
	defer a.mu.Unlock()
	info, ok := a.refreshTokens[token]
	if !ok {
		return sessionInfo{}, false
	}
	delete(a.refreshTokens, token)
	return info, true
}

func (a *AuthStore) isValidAccess(token string) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	_, ok := a.accessTokens[token]
	return ok
}

func loginPageHTML(code string) string {
	return fmt.Sprintf(`<!doctype html>
<html><head><meta charset="utf-8"><title>Mock e-Kréta login</title>
<style>body{font-family:sans-serif;max-width:420px;margin:80px auto;padding:0 16px}
button{width:100%%;padding:12px;font-size:16px;background:#4c6b3a;color:#fff;border:none;border-radius:8px;cursor:pointer}</style>
</head><body>
<h2>Mock e-Kréta bejelentkezés</h2>
<p>Ez a firka mock szerver bejelentkezési képernyője. Nincs szükség valódi felhasználónévre vagy jelszóra.</p>
<form method="get" action="/ellenorzo-student/prod/oauthredirect">
<input type="hidden" name="code" value="%s">
<button type="submit">Belépés mock diákként</button>
</form>
</body></html>`, code)
}

func (s *Server) handleAccountLogin(w http.ResponseWriter, r *http.Request) {
	code := s.auth.issueCode()
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(loginPageHTML(code)))
}

func (s *Server) handleOauthRedirect(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "missing code", http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte("<!doctype html><html><body>OK, code issued: " + code + "</body></html>"))
}

func (s *Server) handleToken(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	cfg := s.store.GetConfig()
	student := s.store.GetStudent()
	grantType := r.FormValue("grant_type")
	log.Printf(
		"connect/token: content-type=%q grant_type=%q username=%q form=%v",
		r.Header.Get("Content-Type"), grantType, r.FormValue("username"), r.Form,
	)

	var info sessionInfo
	switch grantType {
	case "authorization_code":
		code := r.FormValue("code")
		if !s.auth.consumeCode(code) {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		info = sessionInfo{
			instituteCode: cfg.InstituteCode,
			userId:        student.Uid,
			username:      cfg.Username,
		}
	case "refresh_token":
		token := r.FormValue("refresh_token")
		found, ok := s.auth.consumeRefresh(token)
		if !ok {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		info = found
	case "password":
		username := r.FormValue("username")
		password := r.FormValue("password")
		if username != cfg.Username || password != cfg.Password {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		info = sessionInfo{
			instituteCode: cfg.InstituteCode,
			userId:        student.Uid,
			username:      cfg.Username,
		}
	default:
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	access, refresh := s.auth.issueTokens(info)
	idToken := buildIdToken(info.instituteCode, info.userId, info.username)

	resp := map[string]any{
		"id_token":      idToken,
		"access_token":  access,
		"expires_in":    cfg.AccessTokenTTLSeconds,
		"token_type":    "Bearer",
		"refresh_token": refresh,
		"scope":         "openid email offline_access kreta-ellenorzo-webapi.public",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (s *Server) requireAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authz := r.Header.Get("Authorization")
		const prefix = "Bearer "
		if len(authz) <= len(prefix) || authz[:len(prefix)] != prefix {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		token := authz[len(prefix):]
		if !s.auth.isValidAccess(token) {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}
