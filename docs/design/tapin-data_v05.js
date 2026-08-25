/* ============================================================
   TAP IN — shared demo dataset
   Fictional district: Brookfield Township Public Schools (NJ)
   Demo day: Tuesday, May 12, 2026 · current time 9:22 AM
   One source of truth injected into all three demo surfaces.
   ============================================================ */
const TAPIN = (() => {

  // ---------- deterministic name pools (fictional) ----------
  const FIRST = ["Aiden","Maya","Jordan","Sofia","Liam","Zoe","Marcus","Isabella","Ethan","Aaliyah",
    "Noah","Camila","Tyler","Priya","Devon","Grace","Mateo","Hannah","Caleb","Nia",
    "Lucas","Emily","Xavier","Ava","Dylan","Leah","Omar","Chloe","Julian","Sadie",
    "Andre","Mia","Connor","Fatima","Elijah","Ruby","Diego","Nora","Trevor","Jasmine",
    "Kai","Lily","Brandon","Amara","Sean","Valeria","Micah","Harper","Felix","Simone"];
  const LAST = ["Ellis","Ramirez","Chen","Okafor","Sullivan","Patel","Washington","Russo","Kim","Alvarado",
    "Nguyen","Brooks","Herrera","Goldberg","Jackson","Moreau","Singh","O'Connell","Diaz","Whitfield",
    "Thompson","Vasquez","Park","Abara","Delgado","Fitzgerald","Yang","Osei","Kowalski","Rivera",
    "Bennett","Machado","Cho","Ademola","Silva","Novak","Reyes","Grant","Ibrahim","Costa"];

  const name = (i, salt) => {
    const f = FIRST[(i * 7 + salt * 3) % FIRST.length];
    const l = LAST[(i * 11 + salt * 5) % LAST.length];
    return { first: f, last: l, full: `${f} ${l}` };
  };

  // ---------- district ----------
  const district = {
    name: "Brookfield Township Public Schools",
    state: "NJ",
    tagline: "Fictional demo district",
    demoDate: "Tuesday, May 12, 2026",
    demoClock: { h: 9, m: 22, s: 15 },       // “now” for the live demo
    sisProvider: "Clever",
    sisLastSync: "7:02 AM",
    enrollment: 2414,
    schools: ["bhs", "rms", "clms"]
  };

  // ---------- schools ----------
  // series slots (validated palette): bhs=#367acc, rms=#eb6834, clms=#1baf7a
  const schools = {
    // present = in attendance today (includes tardy); present + absent = enrollment
    bhs:  { id:"bhs",  name:"Brookfield High School",   short:"Brookfield HS",  grades:"9–12", enrollment:1184,
            color:"#367acc", present:1121, absent:63, late:19, tapCompliance:96.4, teachersLive:41, classesLive:48,
            periodsToday:[95.4,94.9,94.1,94.6,93.9,94.8,95.0],   // attendance % P1–P7 (P5–7 projected)
            principal:"Dr. Renee Calloway" },
    rms:  { id:"rms",  name:"Riverside Middle School",  short:"Riverside MS",   grades:"6–8",  enrollment:642,
            color:"#eb6834", present:611, absent:31, late:8, tapCompliance:97.8, teachersLive:24, classesLive:26,
            periodsToday:[95.9,95.4,94.8,95.3,94.7,95.1,95.5],
            principal:"Mr. Andre Whitfield" },
    clms: { id:"clms", name:"Cedar Lane Middle School", short:"Cedar Lane MS",  grades:"6–8",  enrollment:588,
            color:"#1baf7a", present:552, absent:36, late:9, tapCompliance:92.9, teachersLive:22, classesLive:24,
            periodsToday:[94.6,94.1,93.3,93.8,93.2,93.9,94.2],
            principal:"Ms. Dana Osei" }
  };

  // 4-week district trend (school-day attendance %, Mon–Fri x4)
  const trendWeeks = ["Apr 13","Apr 20","Apr 27","May 4","May 11"];
  const trends = {
    labels: ["Apr 13","Apr 14","Apr 15","Apr 16","Apr 17",
             "Apr 20","Apr 21","Apr 22","Apr 23","Apr 24",
             "Apr 27","Apr 28","Apr 29","Apr 30","May 1",
             "May 4","May 5","May 6","May 7","May 8",
             "May 11","May 12"],
    bhs:  [93.1,93.8,94.2,93.5,92.4, 94.0,94.6,94.9,94.3,93.2, 94.8,95.1,95.4,94.9,93.8, 95.2,95.6,95.9,95.3,94.4, 95.8,94.7],
    rms:  [95.0,95.4,95.9,95.2,94.1, 95.6,96.0,96.3,95.8,94.9, 96.1,96.4,96.8,96.2,95.3, 96.5,96.9,97.1,96.6,95.8, 97.2,95.2],
    clms: [91.2,91.9,92.4,91.8,90.6, 92.1,92.6,93.0,92.4,91.3, 92.8,93.2,93.6,93.0,91.9, 93.4,93.8,94.1,93.5,92.6, 94.0,93.9]
  };
  // tap compliance trend, district-wide, same labels
  trends.compliance = [90.2,90.8,91.3,90.9,89.8, 91.5,92.0,92.4,91.9,91.0, 92.6,93.1,93.5,93.0,92.1, 93.8,94.2,94.6,94.0,93.2, 95.1,95.9];

  // ---------- featured teacher (Brookfield HS) ----------
  const teacher = {
    name: "Dana Alvarez",
    display: "Ms. Alvarez",
    subject: "Science",
    room: "214",
    school: "bhs",
    email: "d.alvarez@brookfieldtps.org"
  };

  // bell schedule (BHS)
  const bells = [
    { p:1, label:"Period 1", start:"8:00",  end:"8:50"  },
    { p:2, label:"Period 2", start:"9:00",  end:"9:50"  },
    { p:3, label:"Period 3", start:"10:00", end:"10:50" },
    { p:4, label:"Period 4", start:"11:00", end:"11:50" },
    { p:5, label:"Period 5", start:"12:00", end:"12:50" },
    { p:6, label:"Period 6", start:"13:00", end:"13:50" },
    { p:7, label:"Period 7", start:"14:00", end:"14:50" }
  ];

  // ---------- status model ----------
  // in    : tapped on time — apps locked, present
  // late  : tapped after bell — apps locked, marked tardy
  // pend  : no tap yet — needs attention
  // flag  : tapped but blocking disabled mid-class — bypass alert
  // absent: absent in SIS (Clever sync)
  // exempt: policy exemption on file (keeps phone; still counted present via tap)
  const STATUS = {
    in:    { label:"Tapped in",    sub:"Apps locked",        color:"#0ca30c", icon:"lock"   },
    late:  { label:"Late tap",     sub:"Tardy · apps locked", color:"#fab219", icon:"clock"  },
    pend:  { label:"No tap yet",   sub:"Needs attention",    color:"#ec835a", icon:"alert"  },
    flag:  { label:"Bypass alert", sub:"Blocking disabled",  color:"#d03b3b", icon:"shield" },
    absent:{ label:"Absent (SIS)", sub:"Synced from Clever", color:"#898781", icon:"minus"  },
    exempt:{ label:"Exempt",       sub:"Policy exemption",   color:"#52514e", icon:"doc"    }
  };

  // ---------- Ms. Alvarez's classes ----------
  // Period 2 (LIVE at 9:22) — hand-authored roster incl. featured student Jordan Ellis
  const p2Roster = [
    { n:"Jordan Ellis",      s:"in",    t:"8:56:44" },   // ★ featured student (iOS app)
    { n:"Maya Ramirez",      s:"in",    t:"8:57:10" },
    { n:"Aiden Chen",        s:"in",    t:"8:57:31" },
    { n:"Sofia Okafor",      s:"in",    t:"8:57:58" },
    { n:"Liam Sullivan",     s:"in",    t:"8:58:12" },
    { n:"Zoe Patel",         s:"in",    t:"8:58:26" },
    { n:"Marcus Washington", s:"in",    t:"8:58:40" },
    { n:"Isabella Russo",    s:"in",    t:"8:58:55" },
    { n:"Ethan Kim",         s:"in",    t:"8:59:03" },
    { n:"Aaliyah Alvarado",  s:"in",    t:"8:59:19" },
    { n:"Noah Goldberg",     s:"in",    t:"8:59:27" },
    { n:"Camila Herrera",    s:"in",    t:"8:59:41" },
    { n:"Tyler Brooks",      s:"in",    t:"8:59:50" },
    { n:"Priya Singh",       s:"in",    t:"8:59:58" },
    { n:"Devon Jackson",     s:"in",    t:"9:00:04" },
    { n:"Grace O'Connell",   s:"in",    t:"9:00:09" },
    { n:"Mateo Diaz",        s:"in",    t:"9:00:15" },
    { n:"Hannah Moreau",     s:"in",    t:"9:00:22" },
    { n:"Caleb Whitfield",   s:"in",    t:"9:00:31" },
    { n:"Nia Thompson",      s:"in",    t:"9:00:44" },
    { n:"Lucas Vasquez",     s:"late",  t:"9:04:12" },
    { n:"Emily Park",        s:"late",  t:"9:06:36" },
    { n:"Trevor Nguyen",     s:"flag",  t:"8:58:02", flagAt:"9:12:48" },
    { n:"Xavier Abara",      s:"in",    t:"9:01:12" },
    { n:"Ava Delgado",       s:"absent",t:null },
    { n:"Dylan Fitzgerald",  s:"exempt",t:"8:57:44" }
  ];

  // deterministic roster generator for non-live classes
  // taps: on-time = up to ~8 min BEFORE the bell (tap at the door as you arrive);
  //       late    = 3–8 min AFTER the bell. Upcoming classes have no taps yet.
  const genRoster = (count, salt, profile) => {
    const [sh, sm] = profile.start.split(":").map(Number);
    const startSec = sh * 3600 + sm * 60;
    const fmt = sec => `${Math.floor(sec/3600)}:${String(Math.floor(sec/60)%60).padStart(2,"0")}:${String(sec%60).padStart(2,"0")}`;
    const out = [];
    for (let i = 0; i < count; i++) {
      const nm = name(i, salt);
      let s = "in";
      if (profile.absent.includes(i)) s = "absent";
      else if (profile.late.includes(i)) s = "late";
      else if (profile.exempt.includes(i)) s = "exempt";
      let t = null;
      if (!profile.upcoming && s !== "absent") {
        t = s === "late"
          ? fmt(startSec + 180 + (i * 47) % 300)   // 3–8 min after the bell
          : fmt(startSec - 45 - (i * 37) % 435);   // 45s–8 min before the bell
      }
      out.push({ n: nm.full, s, t });
    }
    return out;
  };

  const classes = [
    { id:"p1", period:1, name:"Biology I",           section:"P1 · Rm 214", count:24, status:"done",
      attendance:"22 / 24", compliance:"96%",
      roster: genRoster(24, 1, { start:"8:00", absent:[7,19], late:[3], exempt:[11] }) },
    { id:"p2", period:2, name:"Biology I",           section:"P2 · Rm 214", count:26, status:"live",
      attendance:"25 / 26", compliance:"96%",
      history: [ { n:"Marcus Washington", at:"9:08:14", restoredAt:"9:10:02" } ],
      roster: p2Roster },
    { id:"p4", period:4, name:"AP Biology",          section:"P4 · Rm 214", count:18, status:"upcoming",
      attendance:"—", compliance:"—",
      roster: genRoster(18, 4, { start:"11:00", upcoming:true, absent:[], late:[], exempt:[5] }) },
    { id:"p5", period:5, name:"Environmental Science", section:"P5 · Rm 214", count:27, status:"upcoming",
      attendance:"—", compliance:"—",
      roster: genRoster(27, 5, { start:"12:00", upcoming:true, absent:[], late:[], exempt:[] }) },
    { id:"p7", period:7, name:"Biology Honors",      section:"P7 · Rm 214", count:23, status:"upcoming",
      attendance:"—", compliance:"—",
      roster: genRoster(23, 7, { start:"14:00", upcoming:true, absent:[], late:[], exempt:[9] }) }
  ];

  // live feed for Period 2 (newest first at render; sim appends more)
  const feed = [
    { t:"9:12:48", kind:"flag",   who:"Trevor Nguyen",  msg:"Screen Time authorization disabled mid-class — bypass alert" },
    { t:"9:06:36", kind:"late",   who:"Emily Park",     msg:"Late tap · marked tardy · apps locked" },
    { t:"9:04:12", kind:"late",   who:"Lucas Vasquez",  msg:"Late tap · marked tardy · apps locked" },
    { t:"9:01:00", kind:"sys",    who:"Tap in",          msg:"Bell — attendance snapshot posted to Clever (22 present, 1 absent, 3 outstanding)" },
    { t:"9:00:44", kind:"in",     who:"Nia Thompson",   msg:"Tapped in · apps locked" },
    { t:"9:00:31", kind:"in",     who:"Caleb Whitfield",msg:"Tapped in · apps locked" },
    { t:"9:00:22", kind:"in",     who:"Hannah Moreau",  msg:"Tapped in · apps locked" },
    { t:"9:00:15", kind:"in",     who:"Mateo Diaz",     msg:"Tapped in · apps locked" },
    { t:"9:00:09", kind:"in",     who:"Grace O'Connell",msg:"Tapped in · apps locked" },
    { t:"8:59:58", kind:"in",     who:"Priya Singh",    msg:"Tapped in · apps locked" },
    { t:"8:57:44", kind:"exempt", who:"Dylan Fitzgerald",msg:"Tapped in · policy exemption on file — apps not restricted" },
    { t:"8:56:44", kind:"in",     who:"Jordan Ellis",   msg:"Tapped in · apps locked" }
  ];

  // scripted “live” events the demo can append after load
  const feedSim = [
    { after:6,  kind:"in",   who:"Xavier Abara", msg:"Tapped in · apps locked (resolved — was ‘no tap yet’)", resolves:"Xavier Abara" },
    { after:14, kind:"sys",  who:"Tap in",        msg:"Bypass alert acknowledged by Ms. Alvarez" },
    { after:22, kind:"in",   who:"Trevor Nguyen", msg:"Screen Time re-enabled — apps locked again", resolves:"Trevor Nguyen" }
  ];

  // ---------- featured student (iOS app) ----------
  const student = {
    name: "Jordan Ellis",
    grade: 10,
    school: "Brookfield High School",
    id: "BE-204817",
    todayTaps: 2,
    streakDays: 14,
    schedule: [
      { p:1, cls:"Geometry",        room:"118", teacher:"Mr. Osei",     start:"8:00", end:"8:50",  done:true  },
      { p:2, cls:"Biology I",       room:"214", teacher:"Ms. Alvarez",  start:"9:00", end:"9:50",  live:true  },
      { p:3, cls:"English 10",      room:"102", teacher:"Mrs. Novak",   start:"10:00",end:"10:50" },
      { p:4, cls:"World History",   room:"131", teacher:"Mr. Grant",    start:"11:00",end:"11:50" },
      { p:5, cls:"Lunch",           room:"—",   teacher:"",             start:"12:00",end:"12:50", free:true },
      { p:6, cls:"Spanish II",      room:"127", teacher:"Sra. Machado", start:"13:00",end:"13:50" },
      { p:7, cls:"Phys Ed",        room:"GYM", teacher:"Coach Rivera", start:"14:00",end:"14:50" }
    ],
    blockedApps: ["Instagram","TikTok","Snapchat","YouTube","Discord","Twitch","Reddit","X"],
    allowedApps: ["Phone","Messages","Camera","Calculator","Notes","Canvas"]
  };

  // ---------- district: school leaderboard detail ----------
  const alerts = [
    { t:"9:12 AM", school:"bhs",  level:"critical", msg:"Bypass alert — Rm 214 (Alvarez, P2). 1 device disabled Screen Time mid-class." },
    { t:"9:05 AM", school:"clms", level:"serious",  msg:"Low tap compliance — Rm 22 (Kowalski, P2) at 78% five minutes after bell." },
    { t:"8:41 AM", school:"rms",  level:"warning",  msg:"Tag health — Rm 8 door tag read failures (3 retries). Replacement suggested." },
    { t:"7:02 AM", school:"bhs",  level:"good",     msg:"Clever nightly sync complete — 2,414 enrollments, 9 schedule changes applied." }
  ];

  // ---------- teacher reports (Ms. Alvarez) ----------
  const reports = {
    weekLabel: "Week of May 11–15",
    days: ["Mon May 11","Tue May 12","Wed May 13","Thu May 14","Fri May 15"],
    // class-average attendance % per day (null = not yet occurred)
    attendanceByDay: [96.0, 92.9, null, null, null],
    complianceByDay: [93.5, 95.8, null, null, null],
    tardiesByDay: [4, 2, null, null, null],
    bypassByDay: [0, 1, null, null, null],
    // per-class 4-week averages (for the summary table + bar chart)
    byClass: [
      { id:"p1", cls:"Biology I · P1",        enrolled:24, avgAtt:94.2, avgComp:95.1, tardies4w:9,  bypass4w:0 },
      { id:"p2", cls:"Biology I · P2",        enrolled:26, avgAtt:95.1, avgComp:94.3, tardies4w:12, bypass4w:2 },
      { id:"p4", cls:"AP Biology · P4",       enrolled:18, avgAtt:96.8, avgComp:97.9, tardies4w:3,  bypass4w:0 },
      { id:"p5", cls:"Environmental Sci · P5", enrolled:27, avgAtt:93.4, avgComp:93.0, tardies4w:14, bypass4w:1 },
      { id:"p7", cls:"Biology Honors · P7",   enrolled:23, avgAtt:94.9, avgComp:96.2, tardies4w:7,  bypass4w:0 }
    ],
    complianceTrend4w: [90.8,91.5,92.2,91.6,90.4, 92.0,92.8,93.1,92.5,91.7, 93.0,93.6,94.0,93.3,92.4, 93.8,94.5,94.9,94.1,93.5, 93.5,95.8]
  };

  // weekly report history (teacher) — index order oldest → current
  {
    const labels = ["Apr 13–17", "Apr 20–24", "Apr 27 – May 1", "May 4–8"];
    const days = [["Mon Apr 13","Tue Apr 14","Wed Apr 15","Thu Apr 16","Fri Apr 17"],
                  ["Mon Apr 20","Tue Apr 21","Wed Apr 22","Thu Apr 23","Fri Apr 24"],
                  ["Mon Apr 27","Tue Apr 28","Wed Apr 29","Thu Apr 30","Fri May 1"],
                  ["Mon May 4","Tue May 5","Wed May 6","Thu May 7","Fri May 8"]];
    const attW  = [[94.1,94.6,95.0,94.3,93.2],[94.8,95.3,95.6,95.0,93.9],[95.2,95.6,95.9,95.4,94.2],[95.5,95.9,96.2,95.6,94.5]];
    const compW = [[90.8,91.5,92.2,91.6,90.4],[92.0,92.8,93.1,92.5,91.7],[93.0,93.6,94.0,93.3,92.4],[93.8,94.5,94.9,94.1,93.5]];
    const tardW = [[4,3,2,3,3],[4,3,3,3,3],[3,2,3,2,3],[2,3,2,3,2]];
    const bypW  = [[0,1,0,0,0],[0,0,0,1,0],[0,1,0,0,0],[1,0,0,0,1]];
    const offA  = [-0.9,-0.5,-0.2,0.2], offC = [-2.6,-1.6,-0.9,-0.2];
    const tardC = [[3,4,1,5,2],[3,5,1,4,3],[2,4,1,4,2],[2,4,0,4,2]];   // per class P1,P2,P4,P5,P7
    const bypC  = [[0,1,0,0,0],[0,0,0,1,0],[0,1,0,0,0],[1,1,0,0,0]];
    reports.weeks = labels.map((lb, w) => ({
      label: lb, days: days[w],
      attendanceByDay: attW[w], complianceByDay: compW[w],
      tardiesByDay: tardW[w], bypassByDay: bypW[w],
      byClass: reports.byClass.map((c, i) => ({
        cls: c.cls, enrolled: c.enrolled,
        att: +(c.avgAtt + offA[w]).toFixed(1), comp: +(c.avgComp + offC[w]).toFixed(1),
        tardies: tardC[w][i], bypass: bypC[w][i]
      }))
    }));
    reports.weeks.push({ label: "May 11–15", current: true, days: reports.days,
      attendanceByDay: reports.attendanceByDay, complianceByDay: reports.complianceByDay,
      tardiesByDay: reports.tardiesByDay, bypassByDay: reports.bypassByDay });
  }

  // ---------- classroom tags (Rm 214) ----------
  const tags = [
    { id:"TAG-0214A", location:"Rm 214 · hallway door", status:"healthy", writeLocked:true,
      installed:"Aug 26, 2025", readsToday:46, lastRead:"9:06:36 AM", failures30d:0 }
  ];

  // ---------- district: Clever sync history ----------
  const syncHistory = [
    { d:"Tue, May 12", t:"7:02 AM", recs:2414, changes:9,  status:"ok" },
    { d:"Mon, May 11", t:"7:01 AM", recs:2414, changes:14, status:"ok" },
    { d:"Fri, May 8",  t:"7:03 AM", recs:2412, changes:6,  status:"ok" },
    { d:"Thu, May 7",  t:"7:02 AM", recs:2412, changes:11, status:"ok" },
    { d:"Wed, May 6",  t:"7:04 AM", recs:2411, changes:3,  status:"ok" },
    { d:"Tue, May 5",  t:"7:02 AM", recs:2411, changes:8,  status:"warn", note:"2 records skipped — missing grade level" },
    { d:"Mon, May 4",  t:"7:01 AM", recs:2409, changes:17, status:"ok" }
  ];
  const syncMappings = [
    { k:"Students", v:"2,414 synced", ok:true },
    { k:"Teachers", v:"187 synced", ok:true },
    { k:"Sections", v:"312 synced", ok:true },
    { k:"Terms & bell schedules", v:"3 schools mapped", ok:true },
    { k:"Attendance write-back", v:"Real-time · per tap", ok:true },
    { k:"Exemption flags", v:"41 students (504/IEP/medical)", ok:true }
  ];

  // ---------- district: classrooms needing attention (compliance) ----------
  const lowRooms = [
    { school:"clms", room:"Rm 22",  teacher:"Mr. Kowalski", period:"P2", comp:78, students:23 },
    { school:"clms", room:"Rm 31",  teacher:"Ms. Rivera",   period:"P1", comp:86, students:26 },
    { school:"bhs",  room:"Rm 108", teacher:"Mr. Grant",    period:"P2", comp:88, students:28 }
  ];

  return { district, schools, trends, trendWeeks, teacher, bells, STATUS, classes, feed, feedSim, student, alerts,
           reports, tags, syncHistory, syncMappings, lowRooms };
})();
