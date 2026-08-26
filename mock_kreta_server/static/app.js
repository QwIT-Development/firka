function getPath(obj, path) {
  return path.split(".").reduce((o, k) => (o == null ? undefined : o[k]), obj);
}

function setPath(obj, path, value) {
  const keys = path.split(".");
  let o = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (o[keys[i]] == null || typeof o[keys[i]] !== "object") o[keys[i]] = {};
    o = o[keys[i]];
  }
  o[keys[keys.length - 1]] = value;
}

function nowIso() {
  return new Date().toISOString();
}

async function getJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(url + ": " + res.status);
  return res.json();
}

async function putJSON(url, body) {
  const res = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(url + ": " + res.status);
}

function flash(el, message) {
  el.textContent = message;
  setTimeout(() => {
    if (el.textContent === message) el.textContent = "";
  }, 2000);
}

function cellInput(row, field, onChange) {
  const paths = field.paths || [field.path];
  const value = getPath(row, paths[0]);

  if (field.type === "bool") {
    const input = document.createElement("input");
    input.type = "checkbox";
    input.checked = !!value;
    input.onchange = () => {
      paths.forEach((p) => setPath(row, p, input.checked));
      onChange();
    };
    return input;
  }

  if (field.type === "lines") {
    const textarea = document.createElement("textarea");
    textarea.rows = 2;
    textarea.value = Array.isArray(value) ? value.join("\n") : "";
    textarea.onchange = () => {
      const list = textarea.value.split("\n").map((s) => s.trim()).filter(Boolean);
      paths.forEach((p) => setPath(row, p, list));
      onChange();
    };
    return textarea;
  }

  const input = document.createElement("input");
  input.type = field.type === "number" ? "number" : "text";
  input.value = value == null ? "" : value;
  input.onchange = () => {
    const v = field.type === "number" ? (input.value === "" ? 0 : Number(input.value)) : input.value;
    paths.forEach((p) => setPath(row, p, v));
    onChange();
  }; //i hate js
  return input;
}

function renderTable(container, opts) {
  container.innerHTML = "";

  const toolbar = document.createElement("div");
  toolbar.className = "toolbar";
  const addBtn = document.createElement("button");
  addBtn.textContent = "Add row";
  const saveBtn = document.createElement("button");
  saveBtn.className = "secondary";
  saveBtn.textContent = "Save";
  const resetBtn = document.createElement("button");
  resetBtn.className = "secondary";
  resetBtn.textContent = "Reload";
  const status = document.createElement("span");
  status.className = "status";
  toolbar.append(addBtn, saveBtn, resetBtn, status);
  container.appendChild(toolbar);

  const table = document.createElement("table");
  container.appendChild(table);

  let rows = [];

  function draw() {
    table.innerHTML = "";
    const thead = document.createElement("tr");
    opts.columns.forEach((c) => {
      const th = document.createElement("th");
      th.textContent = c.label;
      thead.appendChild(th);
    });
    thead.appendChild(document.createElement("th"));
    table.appendChild(thead);

    rows.forEach((row, idx) => {
      const tr = document.createElement("tr");
      opts.columns.forEach((field) => {
        const td = document.createElement("td");
        td.appendChild(cellInput(row, field, () => {}));
        tr.appendChild(td);
      });
      const actionTd = document.createElement("td");
      actionTd.className = "row-actions";
      const delBtn = document.createElement("button");
      delBtn.className = "danger";
      delBtn.textContent = "Delete";
      delBtn.onclick = () => {
        rows.splice(idx, 1);
        draw();
      };
      actionTd.appendChild(delBtn);
      tr.appendChild(actionTd);
      table.appendChild(tr);
    });
  }

  addBtn.onclick = () => {
    rows.push(JSON.parse(JSON.stringify(opts.template())));
    draw();
  };

  saveBtn.onclick = async () => {
    try {
      await putJSON(opts.url, rows);
      flash(status, "saved");
    } catch (e) {
      flash(status, "error: " + e.message);
    }
  };

  resetBtn.onclick = load;

  async function load() {
    rows = await getJSON(opts.url);
    draw();
  }

  load();
}

function renderForm(container, opts) {
  container.innerHTML = "";

  const status = document.createElement("span");
  status.className = "status";

  const grid = document.createElement("div");
  grid.className = "form-grid";
  container.appendChild(grid);

  let data = {};

  function draw() {
    grid.innerHTML = "";
    opts.fields.forEach((field) => {
      const label = document.createElement("label");
      label.textContent = field.label;
      grid.appendChild(label);
      grid.appendChild(cellInput(data, field, () => {}));
    });
  }

  const toolbar = document.createElement("div");
  toolbar.className = "toolbar";
  const saveBtn = document.createElement("button");
  saveBtn.textContent = "Save";
  saveBtn.onclick = async () => {
    try {
      if (opts.beforeSave) opts.beforeSave(data);
      await putJSON(opts.url, data);
      flash(status, "saved");
    } catch (e) {
      flash(status, "error: " + e.message);
    }
  };
  toolbar.append(saveBtn, status);
  container.appendChild(toolbar);
  container.appendChild(grid);

  (async () => {
    data = await getJSON(opts.url);
    draw();
  })();

  return {
    getSubArray(path) {
      if (!getPath(data, path)) setPath(data, path, []);
      return getPath(data, path);
    },
  };
}

const subjectTemplate = () => ({
  Uid: "",
  Nev: "",
  Kategoria: { Uid: "1", Nev: "Kötelező", Leiras: "" },
  SortIndex: 0,
});

const nameUidDescTemplate = () => ({ Uid: "", Nev: "", Leiras: "" });

const entities = {
  classGroups: {
    url: "/admin/api/classGroups",
    template: () => ({
      Uid: "",
      Nev: "",
      OsztalyFonok: { Uid: "" },
      OsztalyFonokHelyettes: { Uid: "" },
      OktatasNevelesiKategoria: { Uid: "1", Nev: "Gimnázium", Leiras: "" },
      OktatasNevelesiKategoriaSortIndex: 0,
      OktatasNevelesiFeladat: nameUidDescTemplate(),
      IsAktiv: true,
      Tipus: "Osztaly",
    }),
    columns: [
      { path: "Nev", label: "Name", type: "text" },
      { path: "Uid", label: "UID", type: "text" },
      { path: "Tipus", label: "Type", type: "text" },
      { path: "IsAktiv", label: "Active", type: "bool" },
      { path: "OktatasNevelesiKategoria.Nev", label: "Category", type: "text" },
    ],
  },

  grades: {
    url: "/admin/api/grades",
    template: () => ({
      Uid: "",
      RogzitesDatuma: nowIso(),
      KeszitesDatuma: nowIso(),
      LattamozasDatuma: "",
      Tantargy: subjectTemplate(),
      Tema: "",
      Tipus: { Uid: "1", Nev: "Írásbeli", Leiras: "" },
      Mod: nameUidDescTemplate(),
      ErtekFajta: { Uid: "1", Nev: "Osztályzat", Leiras: "" },
      ErtekeloTanarNeve: "",
      Kind: "",
      SzamErtek: 5,
      SzovegesErtek: "Jeles",
      SulySzazalekErteke: 100,
      SzovegesErtekelesRovidNev: "",
      OsztalyCsoport: { Uid: "" },
      SortIndex: 0,
    }),
    columns: [
      { path: "Tantargy.Nev", label: "Subject", type: "text" },
      { path: "ErtekeloTanarNeve", label: "Teacher", type: "text" },
      { path: "Tipus.Nev", label: "Type", type: "text" },
      { path: "ErtekFajta.Nev", label: "Value type", type: "text" },
      { path: "SzamErtek", label: "Value (number)", type: "number" },
      { path: "SzovegesErtek", label: "Value (text)", type: "text" },
      { path: "Tema", label: "Topic", type: "text" },
      { path: "RogzitesDatuma", label: "Date", type: "text" },
    ],
  },

  homework: {
    url: "/admin/api/homework",
    template: () => ({
      Uid: "",
      Tantargy: subjectTemplate(),
      TantargyNeve: "",
      RogzitoTanarNeve: "",
      Szoveg: "",
      FeladasDatuma: nowIso(),
      HataridoDatuma: nowIso(),
      RogzitesIdopontja: nowIso(),
      IsTanarRogzitette: true,
      IsMegoldva: false,
      IsBeadhato: false,
      OsztalyCsoport: { Uid: "" },
      IsCsatolasEngedelyezes: false,
    }),
    columns: [
      { paths: ["Tantargy.Nev", "TantargyNeve"], label: "Subject", type: "text" },
      { path: "RogzitoTanarNeve", label: "Teacher", type: "text" },
      { path: "Szoveg", label: "Text", type: "text" },
      { path: "FeladasDatuma", label: "Assigned", type: "text" },
      { path: "HataridoDatuma", label: "Due", type: "text" },
      { path: "IsMegoldva", label: "Done", type: "bool" },
      { path: "IsBeadhato", label: "Submittable", type: "bool" },
    ],
  },

  tests: {
    url: "/admin/api/tests",
    template: () => ({
      Uid: "",
      Datum: nowIso(),
      BejelentesDatuma: nowIso(),
      RogzitoTanarNeve: "",
      OrarendiOraOraszama: 1,
      Tantargy: subjectTemplate(),
      TantargyNeve: "",
      Temaja: "",
      Modja: { Uid: "1", Nev: "Írásbeli", Leiras: "" },
      OsztalyCsoport: { Uid: "" },
    }),
    columns: [
      { paths: ["Tantargy.Nev", "TantargyNeve"], label: "Subject", type: "text" },
      { path: "RogzitoTanarNeve", label: "Teacher", type: "text" },
      { path: "Temaja", label: "Topic", type: "text" },
      { path: "Modja.Nev", label: "Method", type: "text" },
      { path: "Datum", label: "Date", type: "text" },
      { path: "BejelentesDatuma", label: "Announced", type: "text" },
    ],
  },

  omissions: {
    url: "/admin/api/omissions",
    template: () => ({
      Uid: "",
      Tantargy: subjectTemplate(),
      Datum: nowIso(),
      RogzitoTanarNeve: "",
      Tipus: { Uid: "1", Nev: "Hiányzás", Leiras: "" },
      Mod: nameUidDescTemplate(),
      KeszitesDatuma: nowIso(),
      IgazolasAllapota: "Igazolt",
      IgazolasTipusa: nameUidDescTemplate(),
      OsztalyCsoport: { Uid: "" },
    }),
    columns: [
      { path: "Tantargy.Nev", label: "Subject", type: "text" },
      { path: "RogzitoTanarNeve", label: "Teacher", type: "text" },
      { path: "Tipus.Nev", label: "Type", type: "text" },
      { path: "IgazolasAllapota", label: "State (Igazolt/Igazolatlan/Igazolando)", type: "text" },
      { path: "Datum", label: "Date", type: "text" },
    ],
  },

  lessons: {
    url: "/admin/api/lessons",
    template: () => ({
      Uid: "",
      Datum: nowIso(),
      KezdetIdopont: nowIso(),
      VegIdopont: nowIso(),
      Nev: "",
      Oraszam: 1,
      OraEvesSorszama: 0,
      OsztalyCsoport: { Uid: "", Nev: "" },
      TanarNeve: "",
      Tantargy: subjectTemplate(),
      Tema: "",
      TeremNeve: "",
      Tipus: { Uid: "1", Nev: "Tanóra", Leiras: "" },
      TanuloJelenlet: nameUidDescTemplate(),
      Allapot: { Uid: "1", Nev: "Megtartott", Leiras: "" },
      HaziFeladatUid: "",
      IsTanuloHaziFeladatEnabled: true,
      IsHaziFeladatMegoldva: false,
      Csatolmanyok: [],
      IsDigitalisOra: false,
      DigitalisTamogatoEszkozTipusList: [],
      Letrehozas: nowIso(),
      UtolsoModositas: nowIso(),
    }),
    columns: [
      { paths: ["Nev", "Tantargy.Nev"], label: "Subject / name", type: "text" },
      { path: "Datum", label: "Date", type: "text" },
      { path: "KezdetIdopont", label: "Start", type: "text" },
      { path: "VegIdopont", label: "End", type: "text" },
      { path: "Oraszam", label: "Lesson #", type: "number" },
      { path: "TanarNeve", label: "Teacher", type: "text" },
      { path: "TeremNeve", label: "Room", type: "text" },
      { path: "Tipus.Nev", label: "Type", type: "text" },
      { path: "Allapot.Nev", label: "State", type: "text" },
    ],
  },

  notices: {
    url: "/admin/api/notices",
    template: () => ({
      Uid: "",
      RogzitoNeve: "",
      ErvenyessegKezdete: nowIso(),
      ErvenyessegVege: nowIso(),
      Cim: "",
      Tartalom: "",
      TartalomText: "",
    }),
    columns: [
      { path: "Cim", label: "Title", type: "text" },
      { path: "RogzitoNeve", label: "Author", type: "text" },
      { paths: ["Tartalom", "TartalomText"], label: "Content", type: "text" },
      { path: "ErvenyessegKezdete", label: "Valid from", type: "text" },
      { path: "ErvenyessegVege", label: "Valid to", type: "text" },
    ],
  },

  infoBoard: {
    url: "/admin/api/infoBoard",
    template: () => ({
      Uid: "",
      Cim: "",
      Datum: nowIso(),
      KeszitoTanarNeve: "",
      KeszitesDatuma: nowIso(),
      Tartalom: "",
      TartalomFormazott: "",
      Tipus: { Uid: "1", Nev: "Dicséret", Leiras: "" },
    }),
    columns: [
      { path: "Cim", label: "Title", type: "text" },
      { path: "KeszitoTanarNeve", label: "Teacher", type: "text" },
      { paths: ["Tartalom", "TartalomFormazott"], label: "Content", type: "text" },
      { path: "Tipus.Nev", label: "Type", type: "text" },
      { path: "Datum", label: "Date", type: "text" },
    ],
  },

  dktSubjects: {
    url: "/admin/api/dktSubjects",
    template: () => ({
      tantargyId: 0,
      tantargyNev: "",
      alkalmazottNev: "",
      csoportId: 0,
      osztalyCsoportNev: "",
      tipusId: 0,
      nyelvId: "",
    }),
    columns: [
      { path: "tantargyNev", label: "Subject", type: "text" },
      { path: "alkalmazottNev", label: "Teacher", type: "text" },
      { path: "osztalyCsoportNev", label: "Group", type: "text" },
      { path: "tipusId", label: "Type ID", type: "number" },
    ],
  },

  averages: {
    url: "/admin/api/averages",
    template: () => ({
      Uid: "",
      Tantargy: subjectTemplate(),
      TanuloAtlag: 0,
      OsztalyCsoportAtlag: 0,
    }),
    columns: [
      { path: "Tantargy.Nev", label: "Subject", type: "text" },
      { path: "TanuloAtlag", label: "Student average", type: "number" },
      { path: "OsztalyCsoportAtlag", label: "Class average", type: "number" },
    ],
  },

  guardians: {
    template: () => ({
      Uid: "",
      Nev: "",
      EmailCim: "",
      IsTorvenyesKepviselo: true,
      Telefonszam: "",
    }),
    columns: [
      { path: "Nev", label: "Name", type: "text" },
      { path: "EmailCim", label: "Email", type: "text" },
      { path: "Telefonszam", label: "Phone", type: "text" },
      { path: "IsTorvenyesKepviselo", label: "Legal guardian", type: "bool" },
    ],
  },
};

function renderStudentPanel(container) {
  container.innerHTML = "<h2>Student profile</h2>";
  const formHost = document.createElement("div");
  container.appendChild(formHost);

  const status = document.createElement("span");
  status.className = "status";

  let data = {};

  const fields = [
    { path: "Nev", label: "Name", type: "text" },
    { path: "EmailCim", label: "Email", type: "text" },
    { path: "Telefonszam", label: "Phone", type: "text" },
    { path: "SzuletesiEv", label: "Birth year", type: "number" },
    { path: "SzuletesiHonap", label: "Birth month", type: "number" },
    { path: "SzuletesiNap", label: "Birth day", type: "number" },
    { path: "Cimek", label: "Addresses (one per line)", type: "lines" },
    { path: "TanevUid", label: "School year UID", type: "text" },
    { path: "IntezmenyAzonosito", label: "Institute code", type: "text" },
    { path: "IntezmenyNev", label: "Institute name", type: "text" },
    { path: "Intezmeny.RovidNev", label: "Institute short name", type: "text" },
  ];

  const grid = document.createElement("div");
  grid.className = "form-grid";

  function drawForm() {
    grid.innerHTML = "";
    fields.forEach((field) => {
      const label = document.createElement("label");
      label.textContent = field.label;
      grid.appendChild(label);
      grid.appendChild(cellInput(data, field, () => {}));
    });
  }

  const toolbar = document.createElement("div");
  toolbar.className = "toolbar";
  const saveBtn = document.createElement("button");
  saveBtn.textContent = "Save student profile";
  toolbar.append(saveBtn, status);

  const guardianHost = document.createElement("div");
  guardianHost.innerHTML = "<h3>Guardians</h3>";
  const guardianTableHost = document.createElement("div");
  guardianHost.appendChild(guardianTableHost);

  container.appendChild(toolbar);
  container.appendChild(grid);
  container.appendChild(guardianHost);

  let guardianRows = [];

  function drawGuardians() {
    guardianTableHost.innerHTML = "";
    const table = document.createElement("table");
    const thead = document.createElement("tr");
    entities.guardians.columns.forEach((c) => {
      const th = document.createElement("th");
      th.textContent = c.label;
      thead.appendChild(th);
    });
    thead.appendChild(document.createElement("th"));
    table.appendChild(thead);

    guardianRows.forEach((row, idx) => {
      const tr = document.createElement("tr");
      entities.guardians.columns.forEach((field) => {
        const td = document.createElement("td");
        td.appendChild(cellInput(row, field, () => {}));
        tr.appendChild(td);
      });
      const actionTd = document.createElement("td");
      const delBtn = document.createElement("button");
      delBtn.className = "danger";
      delBtn.textContent = "Delete";
      delBtn.onclick = () => {
        guardianRows.splice(idx, 1);
        drawGuardians();
      };
      actionTd.appendChild(delBtn);
      tr.appendChild(actionTd);
      table.appendChild(tr);
    });

    guardianTableHost.appendChild(table);

    const addBtn = document.createElement("button");
    addBtn.className = "secondary";
    addBtn.textContent = "Add guardian";
    addBtn.onclick = () => {
      guardianRows.push(entities.guardians.template());
      drawGuardians();
    };
    guardianTableHost.appendChild(addBtn);
  }

  saveBtn.onclick = async () => {
    data.Gondviselok = guardianRows;
    try {
      await putJSON("/admin/api/student", data);
      flash(status, "saved");
    } catch (e) {
      flash(status, "error: " + e.message);
    }
  };

  (async () => {
    data = await getJSON("/admin/api/student");
    guardianRows = data.Gondviselok || [];
    drawForm();
    drawGuardians();
  })();
}

function renderServerPanel(container) {
  container.innerHTML = "<h2>Server settings</h2><p>Long-press the firka logo on the app's login screen to enable mock mode and point it at this server's address, then log in with the username/password configured below.</p>";
  const grid = document.createElement("div");
  grid.className = "form-grid";
  container.appendChild(grid);

  const status = document.createElement("span");
  status.className = "status";

  let data = {};
  const fields = [
    { path: "instituteCode", label: "Institute code", type: "text" },
    { path: "username", label: "Username", type: "text" },
    { path: "password", label: "Password", type: "text" },
    { path: "accessTokenTtlSeconds", label: "Access token TTL (seconds)", type: "number" },
  ];

  function draw() {
    grid.innerHTML = "";
    fields.forEach((field) => {
      const label = document.createElement("label");
      label.textContent = field.label;
      grid.appendChild(label);
      grid.appendChild(cellInput(data, field, () => {}));
    });
  }

  const toolbar = document.createElement("div");
  toolbar.className = "toolbar";
  const saveBtn = document.createElement("button");
  saveBtn.textContent = "Save";
  saveBtn.onclick = async () => {
    try {
      await putJSON("/admin/api/config", data);
      flash(status, "saved");
    } catch (e) {
      flash(status, "error: " + e.message);
    }
  };
  const resetBtn = document.createElement("button");
  resetBtn.className = "danger";
  resetBtn.textContent = "Reset all data to seed defaults";
  resetBtn.onclick = async () => {
    if (!confirm("This replaces every entity with the built-in seed data. Continue?")) return;
    await fetch("/admin/api/reset", { method: "POST" });
    location.reload();
  };
  toolbar.append(saveBtn, resetBtn, status);
  container.appendChild(toolbar);
  container.appendChild(grid);

  (async () => {
    data = await getJSON("/admin/api/config");
    draw();
  })();
}

const tabs = [
  { key: "server", label: "Server", render: renderServerPanel },
  { key: "student", label: "Student", render: renderStudentPanel },
  { key: "classGroups", label: "Class groups", render: (c) => renderTable(c, entities.classGroups) },
  { key: "grades", label: "Grades", render: (c) => renderTable(c, entities.grades) },
  { key: "homework", label: "Homework", render: (c) => renderTable(c, entities.homework) },
  { key: "tests", label: "Tests", render: (c) => renderTable(c, entities.tests) },
  { key: "omissions", label: "Omissions", render: (c) => renderTable(c, entities.omissions) },
  { key: "lessons", label: "Timetable", render: (c) => renderTable(c, entities.lessons) },
  { key: "notices", label: "Notice board", render: (c) => renderTable(c, entities.notices) },
  { key: "infoBoard", label: "Info board", render: (c) => renderTable(c, entities.infoBoard) },
  { key: "dktSubjects", label: "DKT subjects", render: (c) => renderTable(c, entities.dktSubjects) },
  { key: "averages", label: "Class averages", render: (c) => renderTable(c, entities.averages) },
];

function init() {
  const nav = document.getElementById("nav");
  const main = document.getElementById("main");

  tabs.forEach((tab) => {
    const btn = document.createElement("button");
    btn.textContent = tab.label;
    btn.onclick = () => selectTab(tab.key);
    btn.dataset.key = tab.key;
    nav.appendChild(btn);
  });

  function selectTab(key) {
    nav.querySelectorAll("button").forEach((b) => b.classList.toggle("active", b.dataset.key === key));
    const tab = tabs.find((t) => t.key === key);
    main.innerHTML = "";
    const panel = document.createElement("div");
    panel.className = "panel active";
    main.appendChild(panel);
    tab.render(panel);
  }

  selectTab(tabs[0].key);
}

init();
