package main

import "time"

func iso(t time.Time) string {
	return t.Format("2006-01-02T15:04:05")
}

func seedData() storeData {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	mathSubject := Subject{
		Uid:       "1,MATEK",
		Nev:       "Matematika",
		Kategoria: NameUidDesc{Uid: "1", Nev: "Kötelező", Leiras: "Kötelező tantárgy"},
		SortIndex: 1,
	}
	litSubject := Subject{
		Uid:       "2,MAGYAR",
		Nev:       "Magyar nyelv és irodalom",
		Kategoria: NameUidDesc{Uid: "1", Nev: "Kötelező", Leiras: "Kötelező tantárgy"},
		SortIndex: 2,
	}

	classGroup := UidRef{Uid: "10,11.A"}

	return storeData{
		Config: ServerConfig{
			InstituteCode:         "mockschool",
			Username:              "student",
			Password:              "student",
			AccessTokenTTLSeconds: 43200,
		},
		Student: Student{
			Uid: "100",
			Nev: "Teszt Elek",
			Cimek: []string{
				"1234 Budapest, Példa utca 1.",
			},
			Bankszamla: BankAccount{
				BankszamlaSzam:              "",
				IsReadOnly:                  false,
				BankszamlaTulajdonosNeve:    "",
				BankszamlaTulajdonosTipusId: 0,
			},
			SzuletesiEv:        2008,
			SzuletesiHonap:     9,
			SzuletesiNap:       1,
			EmailCim:           "teszt.elek@example.com",
			Telefonszam:        "",
			TanevUid:           "2025/2026",
			IntezmenyAzonosito: "mockschool",
			IntezmenyNev:       "Mock Gimnázium",
			Gondviselok: []Guardian{
				{
					Uid:                  "200",
					Nev:                  "Teszt Anna",
					EmailCim:             "teszt.anna@example.com",
					IsTorvenyesKepviselo: true,
					Telefonszam:          "+36301234567",
				},
			},
			Intezmeny: Institution{
				Uid:      "1",
				RovidNev: "Mock Gimnázium",
				TestreszabasBeallitasok: CustomizationSettings{
					ErtekelesekMegjelenitesenekKesleltetesenekMerteke: 0,
					IsOsztalyAtlagMegjeleniteseEllenorzoben:           true,
					IsTanorakTemajaMegtekinthetoEllenorzoben:          true,
					KovetkezoTelepitesDatuma:                          "",
				},
				Rendszermodulok: []SystemModule{},
			},
		},
		ClassGroups: []ClassGroup{
			{
				Uid:                      classGroup.Uid,
				Nev:                      "11.A",
				OktatasNevelesiKategoria: NameUidDesc{Uid: "1", Nev: "Gimnázium", Leiras: "Nappali gimnáziumi oktatás"},
				IsAktiv:                  true,
				Tipus:                    "Osztaly",
			},
		},
		Grades: []Grade{
			{
				Uid:               "1000",
				RogzitesDatuma:    iso(today.Add(-24 * time.Hour)),
				KeszitesDatuma:    iso(today.Add(-24 * time.Hour)),
				Tantargy:          mathSubject,
				Tema:              "Másodfokú egyenletek",
				Tipus:             NameUidDesc{Uid: "1", Nev: "Írásbeli", Leiras: "Írásbeli felelet"},
				ErtekFajta:        NameUidDesc{Uid: "1", Nev: "Osztályzat", Leiras: "Osztályzat"},
				ErtekeloTanarNeve: "Kovács Béla",
				SzamErtek:         5,
				SzovegesErtek:     "Jeles",
				OsztalyCsoport:    classGroup,
				SortIndex:         1,
			},
		},
		Homework: []Homework{
			{
				Uid:               "2000",
				Tantargy:          litSubject,
				TantargyNeve:      litSubject.Nev,
				RogzitoTanarNeve:  "Nagy Ilona",
				Szoveg:            "Olvassátok el az 5. fejezetet.",
				FeladasDatuma:     iso(today),
				HataridoDatuma:    iso(today.Add(7 * 24 * time.Hour)),
				RogzitesIdopontja: iso(today),
				IsTanarRogzitette: true,
				OsztalyCsoport:    classGroup,
			},
		},
		Tests: []Test{
			{
				Uid:                 "3000",
				Datum:               iso(today.Add(5 * 24 * time.Hour)),
				BejelentesDatuma:    iso(today),
				RogzitoTanarNeve:    "Kovács Béla",
				OrarendiOraOraszama: 2,
				Tantargy:            mathSubject,
				TantargyNeve:        mathSubject.Nev,
				Temaja:              "Trigonometria",
				Modja:               NameUidDesc{Uid: "1", Nev: "Írásbeli", Leiras: "Írásbeli dolgozat"},
				OsztalyCsoport:      classGroup,
			},
		},
		Omissions: []Omission{
			{
				Uid:              "4000",
				Tantargy:         mathSubject,
				Datum:            iso(today.Add(-48 * time.Hour)),
				RogzitoTanarNeve: "Kovács Béla",
				Tipus:            NameUidDesc{Uid: "1", Nev: "Hiányzás", Leiras: "Hiányzás"},
				KeszitesDatuma:   iso(today.Add(-48 * time.Hour)),
				IgazolasAllapota: "Igazolt",
				OsztalyCsoport:   classGroup,
			},
		},
		Lessons: []Lesson{
			{
				Uid:                              "5000",
				Datum:                            iso(today),
				KezdetIdopont:                    iso(today.Add(8 * time.Hour)),
				VegIdopont:                       iso(today.Add(8*time.Hour + 45*time.Minute)),
				Nev:                              mathSubject.Nev,
				Oraszam:                          1,
				OsztalyCsoport:                   NameUid{Uid: classGroup.Uid, Nev: "11.A"},
				TanarNeve:                        "Kovács Béla",
				Tantargy:                         mathSubject,
				TeremNeve:                        "101",
				Tipus:                            NameUidDesc{Uid: "1", Nev: "Tanóra", Leiras: "Normál tanóra"},
				Allapot:                          NameUidDesc{Uid: "1", Nev: "Megtartott", Leiras: "Megtartott óra"},
				IsTanuloHaziFeladatEnabled:       true,
				Csatolmanyok:                     []NameUid{},
				DigitalisTamogatoEszkozTipusList: []string{},
				Letrehozas:                       iso(today.Add(-30 * 24 * time.Hour)),
				UtolsoModositas:                  iso(today.Add(-30 * 24 * time.Hour)),
			},
		},
		Notices: []NoticeBoardItem{
			{
				Uid:                "6000",
				RogzitoNeve:        "Igazgatóság",
				ErvenyessegKezdete: iso(today),
				ErvenyessegVege:    iso(today.Add(14 * 24 * time.Hour)),
				Cim:                "Őszi szünet",
				Tartalom:           "Az őszi szünet előtti utolsó tanítási nap...",
				TartalomText:       "Az őszi szünet előtti utolsó tanítási nap...",
			},
		},
		InfoBoard: []InfoBoardItem{
			{
				Uid:              "7000",
				Cim:              "Osztályfőnöki bejegyzés",
				Datum:            iso(today),
				KeszitoTanarNeve: "Kovács Béla",
				KeszitesDatuma:   iso(today),
				Tartalom:         "Dicséret szorgalmi feladatért.",
				Tipus:            NameUidDesc{Uid: "1", Nev: "Dicséret", Leiras: "Szaktanári dicséret"},
			},
		},
		DktSubjects: []DktSubject{
			{
				TantargyId:        1,
				TantargyNev:       mathSubject.Nev,
				AlkalmazottNev:    "Kovács Béla",
				OsztalyCsoportNev: "11.A",
				TipusId:           0,
			},
		},
		Averages: []ClassGroupSubjectAverage{
			{
				Uid:                 "8000",
				Tantargy:            mathSubject,
				TanuloAtlag:         4.5,
				OsztalyCsoportAtlag: 3.8,
			},
		},
	}
}

//xdd mi a faszom ez kreta 
