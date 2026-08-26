package main

import (
	"encoding/json"
	"os"
	"sync"
)

type UidRef struct {
	Uid string `json:"Uid"`
}

type NameUid struct {
	Uid string `json:"Uid"`
	Nev string `json:"Nev"`
}

type NameUidDesc struct {
	Uid    string `json:"Uid"`
	Nev    string `json:"Nev"`
	Leiras string `json:"Leiras"`
}

type Subject struct {
	Uid       string      `json:"Uid"`
	Nev       string      `json:"Nev"`
	Kategoria NameUidDesc `json:"Kategoria"`
	SortIndex int         `json:"SortIndex"`
}

type Guardian struct {
	Uid                  string `json:"Uid"`
	Nev                  string `json:"Nev"`
	EmailCim             string `json:"EmailCim,omitempty"`
	IsTorvenyesKepviselo bool   `json:"IsTorvenyesKepviselo"`
	Telefonszam          string `json:"Telefonszam,omitempty"`
}

type BankAccount struct {
	BankszamlaSzam              string `json:"BankszamlaSzam,omitempty"`
	IsReadOnly                  bool   `json:"IsReadOnly"`
	BankszamlaTulajdonosNeve    string `json:"BankszamlaTulajdonosNeve,omitempty"`
	BankszamlaTulajdonosTipusId int    `json:"BankszamlaTulajdonosTipusId"`
}

type SystemModule struct {
	IsAktiv bool   `json:"IsAktiv"`
	Tipus   string `json:"Tipus"`
	Url     string `json:"Url,omitempty"`
}

type CustomizationSettings struct {
	ErtekelesekMegjelenitesenekKesleltetesenekMerteke int    `json:"ErtekelesekMegjelenitesenekKesleltetesenekMerteke"`
	IsOsztalyAtlagMegjeleniteseEllenorzoben           bool   `json:"IsOsztalyAtlagMegjeleniteseEllenorzoben"`
	IsTanorakTemajaMegtekinthetoEllenorzoben          bool   `json:"IsTanorakTemajaMegtekinthetoEllenorzoben"`
	KovetkezoTelepitesDatuma                          string `json:"KovetkezoTelepitesDatuma"`
}

type Institution struct {
	Uid                     string                `json:"Uid"`
	RovidNev                string                `json:"RovidNev"`
	TestreszabasBeallitasok CustomizationSettings `json:"TestreszabasBeallitasok"`
	Rendszermodulok         []SystemModule        `json:"Rendszermodulok"`
}

type Student struct {
	Uid                string      `json:"Uid"`
	Nev                string      `json:"Nev"`
	Cimek              []string    `json:"Cimek"`
	Bankszamla         BankAccount `json:"Bankszamla"`
	SzuletesiEv        int         `json:"SzuletesiEv"`
	SzuletesiHonap     int         `json:"SzuletesiHonap"`
	SzuletesiNap       int         `json:"SzuletesiNap"`
	EmailCim           string      `json:"EmailCim,omitempty"`
	Telefonszam        string      `json:"Telefonszam,omitempty"`
	TanevUid           string      `json:"TanevUid"`
	Gondviselok        []Guardian  `json:"Gondviselok"`
	IntezmenyAzonosito string      `json:"IntezmenyAzonosito"`
	IntezmenyNev       string      `json:"IntezmenyNev"`
	Intezmeny          Institution `json:"Intezmeny"`
}

type ClassGroup struct {
	Uid                               string      `json:"Uid"`
	Nev                               string      `json:"Nev"`
	OsztalyFonok                      UidRef      `json:"OsztalyFonok"`
	OsztalyFonokHelyettes             UidRef      `json:"OsztalyFonokHelyettes"`
	OktatasNevelesiKategoria          NameUidDesc `json:"OktatasNevelesiKategoria"`
	OktatasNevelesiKategoriaSortIndex int         `json:"OktatasNevelesiKategoriaSortIndex"`
	OktatasNevelesiFeladat            NameUidDesc `json:"OktatasNevelesiFeladat"`
	IsAktiv                           bool        `json:"IsAktiv"`
	Tipus                             string      `json:"Tipus"`
}

type Grade struct {
	Uid                       string      `json:"Uid"`
	RogzitesDatuma            string      `json:"RogzitesDatuma"`
	KeszitesDatuma            string      `json:"KeszitesDatuma"`
	LattamozasDatuma          string      `json:"LattamozasDatuma,omitempty"`
	Tantargy                  Subject     `json:"Tantargy"`
	Tema                      string      `json:"Tema,omitempty"`
	Tipus                     NameUidDesc `json:"Tipus"`
	Mod                       NameUidDesc `json:"Mod"`
	ErtekFajta                NameUidDesc `json:"ErtekFajta"`
	ErtekeloTanarNeve         string      `json:"ErtekeloTanarNeve"`
	Kind                      string      `json:"Kind,omitempty"`
	SzamErtek                 int         `json:"SzamErtek,omitempty"`
	SzovegesErtek             string      `json:"SzovegesErtek"`
	SulySzazalekErteke        int         `json:"SulySzazalekErteke,omitempty"`
	SzovegesErtekelesRovidNev string      `json:"SzovegesErtekelesRovidNev,omitempty"`
	OsztalyCsoport            UidRef      `json:"OsztalyCsoport"`
	SortIndex                 int         `json:"SortIndex"`
}

type Homework struct {
	Uid                    string  `json:"Uid"`
	Tantargy               Subject `json:"Tantargy"`
	TantargyNeve           string  `json:"TantargyNeve"`
	RogzitoTanarNeve       string  `json:"RogzitoTanarNeve"`
	Szoveg                 string  `json:"Szoveg"`
	FeladasDatuma          string  `json:"FeladasDatuma"`
	HataridoDatuma         string  `json:"HataridoDatuma"`
	RogzitesIdopontja      string  `json:"RogzitesIdopontja"`
	IsTanarRogzitette      bool    `json:"IsTanarRogzitette"`
	IsMegoldva             bool    `json:"IsMegoldva"`
	IsBeadhato             bool    `json:"IsBeadhato"`
	OsztalyCsoport         UidRef  `json:"OsztalyCsoport"`
	IsCsatolasEngedelyezes bool    `json:"IsCsatolasEngedelyezes"`
}

type Test struct {
	Uid                 string      `json:"Uid"`
	Datum               string      `json:"Datum"`
	BejelentesDatuma    string      `json:"BejelentesDatuma"`
	RogzitoTanarNeve    string      `json:"RogzitoTanarNeve"`
	OrarendiOraOraszama int         `json:"OrarendiOraOraszama"`
	Tantargy            Subject     `json:"Tantargy"`
	TantargyNeve        string      `json:"TantargyNeve"`
	Temaja              string      `json:"Temaja,omitempty"`
	Modja               NameUidDesc `json:"Modja"`
	OsztalyCsoport      UidRef      `json:"OsztalyCsoport"`
}

type OmittedLesson struct {
	KezdoDatum string `json:"KezdoDatum"`
	VegDatum   string `json:"VegDatum"`
	Oraszam    int    `json:"Oraszam,omitempty"`
}

type Omission struct {
	Uid              string         `json:"Uid"`
	Tantargy         Subject        `json:"Tantargy"`
	Ora              *OmittedLesson `json:"Ora,omitempty"`
	Datum            string         `json:"Datum"`
	RogzitoTanarNeve string         `json:"RogzitoTanarNeve"`
	Tipus            NameUidDesc    `json:"Tipus"`
	Mod              NameUidDesc    `json:"Mod"`
	KesesPercben     int            `json:"KesesPercben,omitempty"`
	KeszitesDatuma   string         `json:"KeszitesDatuma"`
	IgazolasAllapota string         `json:"IgazolasAllapota"`
	IgazolasTipusa   NameUidDesc    `json:"IgazolasTipusa"`
	OsztalyCsoport   UidRef         `json:"OsztalyCsoport"`
}

type Lesson struct {
	Uid                              string      `json:"Uid"`
	Datum                            string      `json:"Datum"`
	KezdetIdopont                    string      `json:"KezdetIdopont"`
	VegIdopont                       string      `json:"VegIdopont"`
	Nev                              string      `json:"Nev"`
	Oraszam                          int         `json:"Oraszam,omitempty"`
	OraEvesSorszama                  int         `json:"OraEvesSorszama,omitempty"`
	OsztalyCsoport                   NameUid     `json:"OsztalyCsoport"`
	TanarNeve                        string      `json:"TanarNeve,omitempty"`
	Tantargy                         Subject     `json:"Tantargy"`
	Tema                             string      `json:"Tema,omitempty"`
	TeremNeve                        string      `json:"TeremNeve,omitempty"`
	Tipus                            NameUidDesc `json:"Tipus"`
	TanuloJelenlet                   NameUidDesc `json:"TanuloJelenlet"`
	Allapot                          NameUidDesc `json:"Allapot"`
	HelyettesTanarNeve               string      `json:"HelyettesTanarNeve,omitempty"`
	HaziFeladatUid                   string      `json:"HaziFeladatUid,omitempty"`
	FeladatGroupUid                  string      `json:"FeladatGroupUid,omitempty"`
	NyelviFeladatGroupUid            string      `json:"NyelviFeladatGroupUid,omitempty"`
	BejelentettSzamonkeresUid        string      `json:"BejelentettSzamonkeresUid,omitempty"`
	IsTanuloHaziFeladatEnabled       bool        `json:"IsTanuloHaziFeladatEnabled"`
	IsHaziFeladatMegoldva            bool        `json:"IsHaziFeladatMegoldva"`
	Csatolmanyok                     []NameUid   `json:"Csatolmanyok"`
	IsDigitalisOra                   bool        `json:"IsDigitalisOra"`
	DigitalisEszkozTipus             string      `json:"DigitalisEszkozTipus,omitempty"`
	DigitalisPlatformTipus           string      `json:"DigitalisPlatformTipus,omitempty"`
	DigitalisTamogatoEszkozTipusList []string    `json:"DigitalisTamogatoEszkozTipusList"`
	Letrehozas                       string      `json:"Letrehozas"`
	UtolsoModositas                  string      `json:"UtolsoModositas"`
}

type NoticeBoardItem struct {
	Uid                string `json:"Uid"`
	RogzitoNeve        string `json:"RogzitoNeve"`
	ErvenyessegKezdete string `json:"ErvenyessegKezdete"`
	ErvenyessegVege    string `json:"ErvenyessegVege"`
	Cim                string `json:"Cim"`
	Tartalom           string `json:"Tartalom"`
	TartalomText       string `json:"TartalomText"`
}

type InfoBoardItem struct {
	Uid               string      `json:"Uid"`
	Cim               string      `json:"Cim"`
	Datum             string      `json:"Datum"`
	KeszitoTanarNeve  string      `json:"KeszitoTanarNeve"`
	KeszitesDatuma    string      `json:"KeszitesDatuma"`
	Tartalom          string      `json:"Tartalom"`
	TartalomFormazott string      `json:"TartalomFormazott"`
	Tipus             NameUidDesc `json:"Tipus"`
}

type DktSubject struct {
	TantargyId        int    `json:"tantargyId"`
	TantargyNev       string `json:"tantargyNev"`
	AlkalmazottNev    string `json:"alkalmazottNev"`
	CsoportId         int    `json:"csoportId,omitempty"`
	OsztalyCsoportNev string `json:"osztalyCsoportNev"`
	TipusId           int    `json:"tipusId"`
	NyelvId           string `json:"nyelvId,omitempty"`
}

type ClassGroupSubjectAverage struct {
	Uid                 string  `json:"Uid"`
	Tantargy            Subject `json:"Tantargy"`
	TanuloAtlag         float64 `json:"TanuloAtlag,omitempty"`
	OsztalyCsoportAtlag float64 `json:"OsztalyCsoportAtlag,omitempty"`
}

type ServerConfig struct {
	InstituteCode         string `json:"instituteCode"`
	Username              string `json:"username"`
	Password              string `json:"password"`
	AccessTokenTTLSeconds int    `json:"accessTokenTtlSeconds"`
}

type storeData struct {
	Config      ServerConfig               `json:"config"`
	Student     Student                    `json:"student"`
	ClassGroups []ClassGroup               `json:"classGroups"`
	Grades      []Grade                    `json:"grades"`
	Homework    []Homework                 `json:"homework"`
	Tests       []Test                     `json:"tests"`
	Omissions   []Omission                 `json:"omissions"`
	Lessons     []Lesson                   `json:"lessons"`
	Notices     []NoticeBoardItem          `json:"notices"`
	InfoBoard   []InfoBoardItem            `json:"infoBoard"`
	DktSubjects []DktSubject               `json:"dktSubjects"`
	Averages    []ClassGroupSubjectAverage `json:"averages"`
}

type Store struct {
	mu   sync.RWMutex
	path string
	data storeData
}

func NewStore(path string) *Store {
	s := &Store{path: path}
	if raw, err := os.ReadFile(path); err == nil {
		if json.Unmarshal(raw, &s.data) == nil {
			return s
		}
	}
	s.data = seedData()
	s.save()
	return s
}

func (s *Store) save() {
	raw, err := json.MarshalIndent(s.data, "", "  ")
	if err != nil {
		return
	}
	os.WriteFile(s.path, raw, 0o644)
}

func (s *Store) Reset() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data = seedData()
	s.save()
}

func (s *Store) GetConfig() ServerConfig {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Config
}

func (s *Store) SetConfig(v ServerConfig) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Config = v
	s.save()
}

func (s *Store) GetStudent() Student {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Student
}

func (s *Store) SetStudent(v Student) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Student = v
	s.save()
}

func (s *Store) GetClassGroups() []ClassGroup {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.ClassGroups
}

func (s *Store) SetClassGroups(v []ClassGroup) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.ClassGroups = v
	s.save()
}

func (s *Store) GetGrades() []Grade {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Grades
}

func (s *Store) SetGrades(v []Grade) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Grades = v
	s.save()
}

func (s *Store) GetHomework() []Homework {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Homework
}

func (s *Store) SetHomework(v []Homework) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Homework = v
	s.save()
}

func (s *Store) GetTests() []Test {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Tests
}

func (s *Store) SetTests(v []Test) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Tests = v
	s.save()
}

func (s *Store) GetOmissions() []Omission {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Omissions
}

func (s *Store) SetOmissions(v []Omission) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Omissions = v
	s.save()
}

func (s *Store) GetLessons() []Lesson {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Lessons
}

func (s *Store) SetLessons(v []Lesson) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Lessons = v
	s.save()
}

func (s *Store) GetNotices() []NoticeBoardItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Notices
}

func (s *Store) SetNotices(v []NoticeBoardItem) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Notices = v
	s.save()
}

func (s *Store) GetInfoBoard() []InfoBoardItem {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.InfoBoard
}

func (s *Store) SetInfoBoard(v []InfoBoardItem) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.InfoBoard = v
	s.save()
}

func (s *Store) GetDktSubjects() []DktSubject {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.DktSubjects
}

func (s *Store) SetDktSubjects(v []DktSubject) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.DktSubjects = v
	s.save()
}

func (s *Store) GetAverages() []ClassGroupSubjectAverage {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.data.Averages
}

func (s *Store) SetAverages(v []ClassGroupSubjectAverage) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data.Averages = v
	s.save()
}
