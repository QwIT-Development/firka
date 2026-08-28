package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

func fillGradeBlanks(store *Store, grades []Grade) []Grade {
	groups := store.GetClassGroups()
	groupUid := ""
	subjectUid := ""
	if len(groups) > 0 {
		groupUid = groups[0].Uid
	}
	for _, g := range store.GetGrades() {
		if g.Tantargy.Uid != "" {
			subjectUid = g.Tantargy.Uid
			break
		}
	}

	for i := range grades {
		if grades[i].Uid == "" {
			grades[i].Uid = fmt.Sprintf("admin-%d-%d", time.Now().UnixNano(), i)
		}
		if grades[i].OsztalyCsoport.Uid == "" {
			grades[i].OsztalyCsoport.Uid = groupUid
		}
		if grades[i].Tantargy.Uid == "" {
			grades[i].Tantargy.Uid = subjectUid
		}
	}
	return grades
}

func decodeBody(r *http.Request, v any) error {
	defer r.Body.Close()
	return json.NewDecoder(r.Body).Decode(v)
}

func (s *Server) adminCollection(
	get func() any,
	set func(*http.Request) error,
) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			writeJSON(w, get())
		case http.MethodPut:
			if err := set(r); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			w.WriteHeader(http.StatusNoContent)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
		}
	}
}

func (s *Server) registerAdminRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/admin/api/config", s.adminCollection(
		func() any { return s.store.GetConfig() },
		func(r *http.Request) error {
			var v ServerConfig
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetConfig(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/student", s.adminCollection(
		func() any { return s.store.GetStudent() },
		func(r *http.Request) error {
			var v Student
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetStudent(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/classGroups", s.adminCollection(
		func() any { return s.store.GetClassGroups() },
		func(r *http.Request) error {
			var v []ClassGroup
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetClassGroups(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/grades", s.adminCollection(
		func() any { return s.store.GetGrades() },
		func(r *http.Request) error {
			var v []Grade
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetGrades(fillGradeBlanks(s.store, v))
			return nil
		},
	))

	mux.HandleFunc("/admin/api/homework", s.adminCollection(
		func() any { return s.store.GetHomework() },
		func(r *http.Request) error {
			var v []Homework
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetHomework(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/tests", s.adminCollection(
		func() any { return s.store.GetTests() },
		func(r *http.Request) error {
			var v []Test
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetTests(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/omissions", s.adminCollection(
		func() any { return s.store.GetOmissions() },
		func(r *http.Request) error {
			var v []Omission
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetOmissions(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/lessons", s.adminCollection(
		func() any { return s.store.GetLessons() },
		func(r *http.Request) error {
			var v []Lesson
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetLessons(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/notices", s.adminCollection(
		func() any { return s.store.GetNotices() },
		func(r *http.Request) error {
			var v []NoticeBoardItem
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetNotices(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/infoBoard", s.adminCollection(
		func() any { return s.store.GetInfoBoard() },
		func(r *http.Request) error {
			var v []InfoBoardItem
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetInfoBoard(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/dktSubjects", s.adminCollection(
		func() any { return s.store.GetDktSubjects() },
		func(r *http.Request) error {
			var v []DktSubject
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetDktSubjects(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/averages", s.adminCollection(
		func() any { return s.store.GetAverages() },
		func(r *http.Request) error {
			var v []ClassGroupSubjectAverage
			if err := decodeBody(r, &v); err != nil {
				return err
			}
			s.store.SetAverages(v)
			return nil
		},
	))

	mux.HandleFunc("/admin/api/reset", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}
		s.store.Reset()
		w.WriteHeader(http.StatusNoContent)
	})
}
