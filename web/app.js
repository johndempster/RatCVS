"use strict";

const HEADER_BYTES = 20400;
const NUM_CHANNELS = 5;
const TSCALE = 1 / 20;
const MAX_ADC = 2047;
const NONE = -1;

const CHANNELS = [
  { key: "abp", name: "ABP", units: "mmHg", scale: 300 / MAX_ADC, color: "#c3423f", min: 0, max: 200 },
  { key: "lvp", name: "LVP", units: "mmHg", scale: 300 / MAX_ADC, color: "#0f7a7a", min: 0, max: 200 },
  { key: "vbp", name: "VBP", units: "mmHg", scale: 50 / MAX_ADC, color: "#315f9e", min: 0, max: 20 },
  { key: "hf", name: "HF", units: "", scale: 20 / MAX_ADC, color: "#7a4aa0", min: 0, max: 20 },
  { key: "hr", name: "HR", units: "BPM", scale: 1600 / MAX_ADC, color: "#cf7b1f", min: 0, max: 800 },
];
const HR_CHANNEL_INDEX = CHANNELS.findIndex((channel) => channel.key === "hr");

const $ = (selector) => document.querySelector(selector);

class ElementState {
  constructor({ conductance, elastance, volume0, volume, rate = 0 }) {
    this.conductance = conductance;
    this.elastance = elastance;
    this.volume0 = volume0;
    this.volume = volume;
    this.rate = rate;
    this.pressure = 0;
    this.maxPressure = 0;
    this.minPressure = 300;
    this.meanPressure = 90;
    this.flow = 0;
    this.nextBeat = 0;
    this.time = 0;
    this.tSystole = 0;
    this.force = 0;
    this.initRange();
  }

  initRange() {
    this.pressureHi = -1e38;
    this.pressureLo = 1e38;
    this.tHi = 0;
    this.tLo = 0;
  }

  calculatePressureRange(time) {
    if (this.pressure <= this.pressureLo) {
      this.pressureLo = this.pressure;
      this.tLo = time;
    }
    if (this.pressure >= this.pressureHi) {
      this.pressureHi = this.pressure;
      this.tHi = time;
    }
  }

  leadingPressure() {
    return this.tLo <= this.tHi ? this.pressureLo : this.pressureHi;
  }

  trailingPressure() {
    return this.tHi >= this.tLo ? this.pressureHi : this.pressureLo;
  }
}

class Drug {
  constructor(name, shortName) {
    this.name = name;
    this.shortName = shortName;
    this.dose = 0;
    this.doseInjected = 0;
    this.onRate = 0.005;
    this.removalRate = 0.0005;
    this.minDose = 0.001;
    this.maxDose = 1;
    for (const receptor of RatSimulation.receptors) {
      this[receptor] = { potency: NONE, efficacy: NONE };
    }
  }
}

class RatSimulation {
  static receptors = [
    "alpha1", "alpha2", "beta1", "beta2", "mus", "vag", "nic",
    "hmCa", "smCa", "aden", "k", "nox", "nos", "angt1", "angt2",
    "brad", "ace", "dig", "pde",
  ];

  constructor() {
    this.reset();
  }

  reset() {
    this.points = [];
    this.markers = [];
    this.pithed = true;
    this.dead = false;
    this.dying = 0;
    this.fibrillation = 0;
    this.time = { time: 0, step: 0.125e-3, next: -1 };
    this.heart = new ElementState({ conductance: 2500, elastance: 1 / 30, volume0: 5, volume: 10, rate: 400 });
    this.art = new ElementState({ conductance: 0.05, elastance: 1 / 0.8, volume0: 100, volume: 150 });
    this.ven = new ElementState({ conductance: 5000, elastance: 1 / 30, volume0: 300, volume: 600 });
    this.con = new ElementState({ conductance: 0, elastance: 0, volume0: 0, volume: 0 });
    this.drugs = [];
    this.indices = {};
    this.receptorLevels = Object.fromEntries(RatSimulation.receptors.map((name) => [name, 0]));
    this.createDrugs();
  }

  createDrug(name, shortName) {
    const drug = new Drug(name, shortName);
    this.drugs.push(drug);
    return drug;
  }

  agonist(drug, receptor, potency) {
    drug[receptor] = { potency: potency * this.noise(0.5), efficacy: 1 };
  }

  antagonist(drug, receptor, potency) {
    drug[receptor] = { potency: potency * this.noise(0.5), efficacy: 0 };
  }

  createDrugs() {
    // 本体(RATMAIN.PAS L434-437)の値に一致させる
    const fastOn = 0.006;
    const fastOff = 0.0035;
    const slowOn = 0.002;
    const slowOff = 5e-4;
    const add = (name, shortName, setup) => {
      const drug = this.createDrug(name, shortName);
      setup(drug);
      return drug;
    };

    add("Adrenaline", "Adr", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-4; d.maxDose = 1e-1;
      this.agonist(d, "alpha1", 5e-3); this.agonist(d, "beta1", 3.5e-3); this.agonist(d, "beta2", 5e-3);
    });
    add("Noradrenaline", "Nor", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-3; d.maxDose = 1;
      this.agonist(d, "alpha1", 1e-2); this.agonist(d, "beta1", 1.5e-2); this.agonist(d, "beta2", 1.5e-1);
    });
    add("Isoprenaline", "Iso", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-4; d.maxDose = 1e-1;
      this.agonist(d, "beta1", 1e-3); this.agonist(d, "beta2", 7e-4);
    });
    add("Phenylephrine", "Phe", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-3; d.maxDose = 1;
      this.agonist(d, "alpha1", 1e-2);
    });
    add("Acetylcholine", "Ach", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff * 2; d.minDose = 1e-3; d.maxDose = 1;
      this.agonist(d, "mus", 5e-3); this.agonist(d, "nic", 0.15); this.agonist(d, "alpha1", 0.3); this.agonist(d, "beta1", 0.15);
    });
    add("Adenosine", "Ade", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 0.1; d.maxDose = 100;
      this.agonist(d, "aden", 1);
    });
    add("Cromakalim", "Cro", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.agonist(d, "k", 0.3);
    });
    const an1 = add("Angiotensin I", "An1", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-4; d.maxDose = 1e-2;
      this.agonist(d, "angt1", 1e-4);
    });
    this.indices.angiotensin1 = this.drugs.indexOf(an1);
    add("Angiotensin II", "An2", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-4; d.maxDose = 1e-2;
      this.agonist(d, "angt2", 1e-4);
    });
    this.lastAgonist = this.drugs.length - 1;

    add("Propranolol", "Pro", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.01; d.maxDose = 100;
      this.antagonist(d, "beta1", 0.5); this.antagonist(d, "beta2", 0.5);
    });
    add("Atenolol", "Ate", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.antagonist(d, "beta1", 10);
    });
    add("Phentolamine", "Phe", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.01; d.maxDose = 10;
      this.antagonist(d, "alpha1", 0.1); this.antagonist(d, "alpha2", 0.1);
    });
    add("Prazosin", "Pra", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.01; d.maxDose = 10;
      this.antagonist(d, "alpha1", 0.1);
    });
    add("Atropine", "Atr", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.01; d.maxDose = 10;
      this.antagonist(d, "mus", 0.1); this.antagonist(d, "vag", 0.1);
    });
    add("8-s-p-theophylline", "8spt", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.antagonist(d, "aden", 5);
    });
    add("Verapamil", "Ver", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.agonist(d, "hmCa", 0.75); this.agonist(d, "smCa", 0.75);
    });
    add("L-NOARG", "LNO", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "nos", 10);
    });
    add("Captopril", "Cap", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "ace", 5);
    });
    add("Losartan", "Los", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.antagonist(d, "angt2", 1);
    });
    add("Digoxin", "Dig", (d) => {
      d.onRate = slowOn * 0.25; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.agonist(d, "dig", 0.5);
    });
    add("Glyceryl trinitrate", "GTN", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "nox", 10);
    });
    add("Milrinone", "Mil", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "pde", 10);
    });
    add("Glibenclamide", "Gli", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.antagonist(d, "k", 1);
    });
    this.lastAntagonist = this.drugs.length - 1;

    // 未知薬 A〜K（学生が正体を同定する教育用課題。本体 RATMAIN.PAS L680-775）
    add("Drug A", "A", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-3; d.maxDose = 1;
      this.agonist(d, "mus", 5e-3); this.agonist(d, "nic", 0.1); this.agonist(d, "alpha1", 0.3); this.agonist(d, "beta1", 0.15);
    });
    add("Drug B", "B", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 0.1; d.maxDose = 1000;
      this.agonist(d, "aden", 1);
    });
    add("Drug C", "C", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1e-4; d.maxDose = 1e-1;
      this.agonist(d, "beta1", 1e-3); this.agonist(d, "beta2", 7e-4);
    });
    add("Drug D", "D", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-3; d.maxDose = 1;
      this.agonist(d, "alpha1", 1e-2); this.agonist(d, "beta1", 1.5e-2); this.agonist(d, "beta2", 1.5e-1);
    });
    add("Drug E", "E", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "nox", 15);
    });
    add("Drug F", "F", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "k", 0.3);
    });
    add("Drug G", "G", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "pde", 10);
    });
    add("Drug H", "H", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.antagonist(d, "beta1", 10); this.antagonist(d, "beta2", 10);
    });
    add("Drug I", "I", (d) => {
      d.onRate = slowOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.agonist(d, "hmCa", 0.75); this.agonist(d, "smCa", 0.75);
    });
    add("Drug J", "J", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 1; d.maxDose = 1000;
      this.agonist(d, "nos", 10);
    });
    add("Drug K", "K", (d) => {
      d.onRate = fastOn; d.removalRate = slowOff; d.minDose = 0.1; d.maxDose = 100;
      this.antagonist(d, "mus", 0.1); this.antagonist(d, "vag", 0.1);
    });
    this.lastUnknown = this.drugs.length - 1;

    const nerve = (key, name, shortName, receptor, potency, on, off) => {
      const drug = add(name, shortName, (d) => {
        d.onRate = on; d.removalRate = off; this.agonist(d, receptor, potency);
      });
      this.indices[key] = this.drugs.indexOf(drug);
    };
    nerve("sympHeart", "Cardiac", "Symp(H)", "beta1", 1.5e-2, fastOn * 4, fastOff * 4);
    const adrenal = add("AdrenalNerve", "Symp(AD)", (d) => {
      d.onRate = fastOn * 2; d.removalRate = fastOff;
      this.agonist(d, "alpha1", 5e-3); this.agonist(d, "beta1", 3.55e-3); this.agonist(d, "beta2", 5e-3);
    });
    this.indices.sympAdrenal = this.drugs.indexOf(adrenal);
    const vessels = add("SympNerve", "Symp(-AD)", (d) => {
      d.onRate = fastOn * 7; d.removalRate = fastOff * 4;
      this.agonist(d, "alpha1", 1e-2); this.agonist(d, "beta1", 1.5e-2); this.agonist(d, "beta2", 1.5e-1);
    });
    this.indices.sympVessels = this.drugs.indexOf(vessels);
    nerve("vagus", "Vagus", "Vag. Nv.", "vag", 5e-3, fastOn * 4, fastOn * 4);
    nerve("renal", "Renal", "Ren. Nv.", "angt1", 2e-4, fastOn, fastOff);
    nerve("alpha1Nerves", "Alpha1", "???", "alpha1", 1e-2, fastOn, fastOff * 2);
    nerve("beta1Nerves", "Beta1", "???", "beta1", 1e-2, fastOn, fastOff * 2);
    const aceAn2 = add("AngiotensinIIACE", "An2", (d) => {
      d.onRate = fastOn; d.removalRate = fastOff; d.minDose = 1e-4; d.maxDose = 1e-2;
      this.agonist(d, "angt2", 1e-4);
    });
    this.indices.angiotensin2ACE = this.drugs.indexOf(aceAn2);
  }

  pressure(element) {
    return Math.max((element.volume - element.volume0) * element.elastance, 0);
  }

  noise(proportion) {
    return 1 + proportion * ((Math.random() * 2) - 1);
  }

  receptorActivation(receptor, potencyShift = 1) {
    let numerator = 0;
    let denominator = 1;
    for (let i = 0; i < this.drugs.length; i += 1) {
      const drug = this.drugs[i];
      const props = drug[receptor];
      if (props.efficacy === NONE || props.potency <= 0) continue;
      const x = drug.dose / (props.potency * potencyShift);
      numerator += props.efficacy * x;
      denominator += x;
    }
    return denominator > 0 ? numerator / denominator : 0;
  }

  inject(drugIndex, dose) {
    const drug = this.drugs[drugIndex];
    if (!drug) return;
    drug.doseInjected = dose * this.noise(0.1);
    this.markers.push({
      point: this.points.length,
      text: `${drug.shortName} ${formatDose(dose)}`,
    });
  }

  stimulate(kind) {
    const drug = this.drugs[this.indices[kind]];
    if (!drug) return;
    const receptor = kind === "renal" ? "angt1" : kind === "vagus" ? "vag" : "beta1";
    const potency = drug[receptor]?.potency || 0.01;
    const multipliers = { sympVessels: 4, sympHeart: 5, sympAdrenal: 2, renal: 5, vagus: 10 };
    // 血管/心臓への交感神経刺激のみ α2 受容体活性で修飾される（本体 RATMAIN.PAS L1769-1777）
    const factor = (kind === "sympVessels" || kind === "sympHeart")
      ? (0.5 + (this.receptorLevels.alpha2 || 0))
      : 1;
    drug.doseInjected = (multipliers[kind] || 4) * potency * factor;
    this.markers.push({ point: this.points.length, text: drug.shortName });
  }

  step() {
    const t = this.time;
    const drugs = this.drugs;
    const idx = this.indices;

    if (t.time >= t.next) {
      drugs[idx.renal].dose = Math.max(drugs[idx.renal].dose, drugs[idx.renal].angt1.potency * 0.25);

      if (!this.pithed) {
        drugs[idx.alpha1Nerves].dose = drugs[idx.alpha1Nerves].alpha1.potency * 0.4;
        drugs[idx.beta1Nerves].dose = drugs[idx.beta1Nerves].beta1.potency * 0.2;
        drugs[idx.vagus].dose = Math.max(
          drugs[idx.vagus].dose,
          drugs[idx.vagus].vag.potency * (5 / (1 + Math.exp(-(this.art.meanPressure - 130) / 8)))
        );
      }

      for (const drug of drugs) {
        drug.dose = Math.max(drug.dose + drug.onRate * (drug.doseInjected - drug.dose) - (drug.dose * drug.removalRate), 0);
        drug.doseInjected = Math.max(drug.doseInjected - drug.doseInjected * drug.removalRate, 0);
      }

      const r = this.receptorLevels;
      r.mus = this.receptorActivation("mus");
      r.vag = this.receptorActivation("vag");
      r.pde = this.receptorActivation("pde");
      r.alpha1 = this.receptorActivation("alpha1");
      r.alpha2 = this.receptorActivation("alpha2");
      const potencyShift = 1 - r.pde * 0.5;
      r.beta1 = this.receptorActivation("beta1", potencyShift);
      r.beta2 = this.receptorActivation("beta2", potencyShift);
      r.hmCa = this.receptorActivation("hmCa");
      r.dig = this.receptorActivation("dig");
      r.smCa = this.receptorActivation("smCa");
      r.aden = this.receptorActivation("aden");
      r.k = this.receptorActivation("k");
      r.nos = this.receptorActivation("nos");
      r.nox = this.receptorActivation("nox");
      r.angt1 = this.receptorActivation("angt1");
      r.ace = this.receptorActivation("ace");
      drugs[idx.angiotensin2ACE].dose = drugs[idx.angiotensin2ACE].angt2.potency * 5 * (1 - r.ace) * (r.angt1 / (1 + r.angt1));
      r.angt2 = this.receptorActivation("angt2");
      r.brad = this.receptorActivation("brad");
      t.next = t.time + 0.005;
    }

    const r = this.receptorLevels;
    this.art.conductance = 5 * (
      1 + 2.5 * r.mus * (1 - r.nos) + 1.9 * r.beta2 + 2.5 * r.aden + 2 * r.nox +
      2 * r.pde + 0.95 * r.smCa + 0.95 * r.k + r.brad - 0.6 * r.nos -
      1.35 * r.alpha1 - 0.9 * r.angt2
    );
    this.art.conductance = Math.max(this.art.conductance, 0.25);
    this.art.elastance = (1 / 0.8) * (1 + 0.2 * r.alpha1);
    this.ven.elastance = (1 / 30) * (1 - 0.7 * Math.min(1, r.nox + r.smCa - r.alpha1));

    this.heart.initRange();
    this.art.initRange();
    this.ven.initRange();
    this.con.initRange();

    for (let i = 0; i < 100; i += 1) {
      if (t.time >= this.heart.nextBeat) {
        this.art.meanPressure = (this.art.maxPressure - this.art.minPressure) * 0.33 + this.art.minPressure;
        this.art.minPressure = 300;
        this.art.maxPressure = 0;
        this.heart.rate = Math.max(1 + 350 * (1 - 0.7 * r.vag - r.mus - r.aden + r.beta1 - r.hmCa + r.pde), 1);
        this.heart.force = 8 * (1 - 0.95 * r.mus - 0.95 * r.aden - 0.6 * r.k + 1.5 * r.beta1 + r.dig + r.pde) *
          (1 - r.hmCa) * (1 / (1 + this.heart.volume0 / this.heart.volume));
        this.heart.time = Math.min(12 / 400, 12 / this.heart.rate);
        this.heart.tSystole = this.heart.time;
        this.heart.nextBeat = t.time + (60 / this.heart.rate);
      }

      if (this.heart.time > 0) {
        const tMid = t.step * Math.round((this.heart.tSystole * 0.5) / t.step);
        const x = (this.heart.time - tMid) / (tMid * 0.33);
        this.heart.elastance = Math.exp(-x * x) * this.heart.force + this.ven.elastance * 4;
        this.heart.time -= t.step;
      }

      if (r.dig > 0.95) {
        this.heart.elastance = this.heart.force * this.noise(0.5) * 0.25;
        this.fibrillation += t.step;
        this.heart.rate = 300 * this.noise(0.5);
        this.heart.pressure = 50 * this.noise(1);
      } else {
        this.heart.pressure = this.pressure(this.heart);
      }

      this.con.pressure = this.heart.elastance;

      if (this.heart.pressure >= this.art.pressure && this.fibrillation <= 0) {
        this.heart.flow = (this.heart.pressure - this.art.pressure) * this.heart.conductance;
        this.art.volume += this.heart.flow * t.step;
        this.heart.volume -= this.heart.flow * t.step;
      }

      this.art.pressure = this.pressure(this.art);
      this.art.maxPressure = Math.max(this.art.maxPressure, this.art.pressure);
      this.art.minPressure = Math.min(this.art.minPressure, this.art.pressure);

      this.art.flow = (this.art.pressure - this.ven.pressure) * this.art.conductance;
      this.ven.volume += this.art.flow * t.step;
      this.art.volume -= this.art.flow * t.step;
      this.ven.pressure = this.pressure(this.ven);

      if (this.ven.pressure >= this.heart.pressure && this.fibrillation <= 0) {
        this.ven.flow = (this.ven.pressure - this.heart.pressure) * this.ven.conductance;
        this.heart.volume += this.ven.flow * t.step;
        this.ven.volume -= this.ven.flow * t.step;
      }

      t.time += t.step;
      this.heart.calculatePressureRange(t.time);
      this.art.calculatePressureRange(t.time);
      this.ven.calculatePressureRange(t.time);
      this.con.calculatePressureRange(t.time);
    }

    if (!this.dead) {
      this.dying = this.art.pressure < 20 ? this.dying + 1 : 0;
      if (this.dying === 500) {
        this.dead = true;
        // step() 内ではローカル変数 t が this.time を指すため、翻訳は別名ヘルパー経由で呼ぶ
        this.markers.push({ point: this.points.length, text: translate("ratDied") });
      }
    }

    this.points.push([
      this.art.leadingPressure(),
      this.heart.leadingPressure(),
      this.ven.leadingPressure(),
      this.con.leadingPressure(),
      this.heart.rate * this.noise(0.05),
    ]);
    this.points.push([
      this.art.trailingPressure(),
      this.heart.trailingPressure(),
      this.ven.trailingPressure(),
      this.con.trailingPressure(),
      this.heart.rate,
    ]);
  }
}

class ChartRenderer {
  constructor(canvas, readout, scrollEl) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.readout = readout;
    this.scrollEl = scrollEl || canvas.parentElement;
    this.visible = CHANNELS.map(() => true);
    this.points = [];
    this.markers = [];
    this.start = 0;
    this.windowSize = 4000;
    this.hover = null;
    this.pixelRatio = window.devicePixelRatio || 1;
    this.resize();
    window.addEventListener("resize", () => this.resize());
    canvas.addEventListener("mousemove", (event) => this.onHover(event));
    canvas.addEventListener("mouseleave", () => {
      this.hover = null;
      readout.hidden = true;
      this.draw();
    });
  }

  resize() {
    this.updateCanvasWidth();
    const rect = this.canvas.getBoundingClientRect();
    this.pixelRatio = window.devicePixelRatio || 1;
    this.canvas.width = Math.max(640, Math.round(rect.width * this.pixelRatio));
    this.canvas.height = Math.max(240, Math.round(rect.height * this.pixelRatio));
    this.ctx.setTransform(this.pixelRatio, 0, 0, this.pixelRatio, 0, 0);
    this.draw();
  }

  setData(points, markers = []) {
    this.points = points;
    this.markers = markers;
    this.resize();
    this.draw();
  }

  updateCanvasWidth() {
    const viewportWidth = Math.max(320, this.scrollEl.clientWidth || this.canvas.parentElement.clientWidth || 0);
    const points = Math.max(this.points.length, 1);
    const visiblePoints = Math.max(this.windowSize, 1);
    const width = Math.max(viewportWidth, Math.ceil(viewportWidth * (points / visiblePoints)));
    this.canvas.style.width = `${Math.min(width, 60000)}px`;
  }

  updateStartFromScroll() {
    const maxStart = Math.max(0, this.points.length - this.windowSize);
    const maxScroll = Math.max(1, this.scrollEl.scrollWidth - this.scrollEl.clientWidth);
    this.start = Math.round((this.scrollEl.scrollLeft / maxScroll) * maxStart);
    return this.start;
  }

  scrollToStart(start) {
    const maxStart = Math.max(0, this.points.length - this.windowSize);
    this.start = clamp(Math.round(start), 0, maxStart);
    const maxScroll = Math.max(1, this.scrollEl.scrollWidth - this.scrollEl.clientWidth);
    this.scrollEl.scrollLeft = maxStart > 0 ? (this.start / maxStart) * maxScroll : 0;
  }

  indexAtClientX(clientX) {
    const rect = this.canvas.getBoundingClientRect();
    const plot = this.plotRect();
    const x = clamp(clientX - rect.left, plot.left, plot.right);
    const d = this.domain();
    return clamp(
      Math.round(d.start + ((x - plot.left) / plot.width) * (d.count - 1)),
      d.start,
      Math.max(d.end - 1, d.start)
    );
  }

  scrollToIndexAtClientX(index, clientX) {
    const scrollRect = this.scrollEl.getBoundingClientRect();
    const plot = this.plotRect();
    const d = this.domain();
    const ratio = d.count > 1 ? (index - d.start) / (d.count - 1) : 0;
    const anchorCanvasX = plot.left + ratio * plot.width;
    const viewportX = clientX - scrollRect.left;
    const maxScroll = Math.max(0, this.scrollEl.scrollWidth - this.scrollEl.clientWidth);
    this.scrollEl.scrollLeft = clamp(anchorCanvasX - viewportX, 0, maxScroll);
    this.updateStartFromScroll();
  }

  plotRect() {
    const rect = this.canvas.getBoundingClientRect();
    return { left: 54, top: 24, right: rect.width - 24, bottom: rect.height - 42, width: rect.width - 78, height: rect.height - 66 };
  }

  domain() {
    return { start: 0, end: this.points.length, count: Math.max(this.points.length, this.windowSize, 1) };
  }

  visiblePointRange() {
    const start = clamp(Math.round(this.start), 0, Math.max(this.points.length - 1, 0));
    const end = clamp(Math.round(this.start + this.windowSize), start, this.points.length);
    return { start, end };
  }

  visibleRangeStats() {
    const { start, end } = this.visiblePointRange();
    const stats = CHANNELS.map(() => ({ min: Infinity, max: -Infinity, count: 0 }));
    for (let i = start; i < end; i += 1) {
      const point = this.points[i];
      if (!point) continue;
      for (let ch = 0; ch < CHANNELS.length; ch += 1) {
        const value = displayChannelValue(this.points, i, ch);
        if (!Number.isFinite(value)) continue;
        stats[ch].min = Math.min(stats[ch].min, value);
        stats[ch].max = Math.max(stats[ch].max, value);
        stats[ch].count += 1;
      }
    }
    return stats.map((stat, index) => ({
      channel: CHANNELS[index],
      visible: this.visible[index],
      min: stat.count > 0 ? stat.min : null,
      max: stat.count > 0 ? stat.max : null,
    }));
  }

  onHover(event) {
    const rect = this.canvas.getBoundingClientRect();
    const plot = this.plotRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    if (x < plot.left || x > plot.right || y < plot.top || y > plot.bottom || this.points.length === 0) {
      this.hover = null;
      this.readout.hidden = true;
      this.draw();
      return;
    }
    const d = this.domain();
    const rawIndex = Math.round(d.start + ((x - plot.left) / plot.width) * (d.count - 1));
    if (rawIndex < d.start || rawIndex >= d.end) {
      this.hover = null;
      this.readout.hidden = true;
      this.draw();
      return;
    }
    const index = clamp(rawIndex, d.start, d.end - 1);
    this.hover = { x, y, index };
    this.updateReadout(index);
    this.draw();
  }

  updateReadout(index) {
    const point = this.points[index];
    if (!point) return;
    $("#readoutTime").textContent = `${(index * TSCALE).toFixed(2)} s`;
    $("#readoutIndex").textContent = `#${index}`;
    $("#readoutRows").innerHTML = CHANNELS.map((channel, i) => {
      const value = displayChannelValue(this.points, index, i);
      const units = channel.units ? ` ${channel.units}` : "";
      return `<tr><td><span class="channel-swatch" style="background:${channel.color}"></span>${channel.name}</td><td>${value.toFixed(i === HR_CHANNEL_INDEX ? 0 : 1)}${units}</td></tr>`;
    }).join("");
    this.readout.hidden = false;
  }

  draw() {
    const rect = this.canvas.getBoundingClientRect();
    const ctx = this.ctx;
    ctx.clearRect(0, 0, rect.width, rect.height);
    const plot = this.plotRect();
    this.drawFrame(ctx, plot);
    if (this.points.length === 0) {
      ctx.fillStyle = "#687782";
      ctx.font = "700 14px system-ui";
      ctx.fillText(t("emptyChart"), plot.left + 18, plot.top + 34);
      return;
    }
    this.drawMarkers(ctx, plot);
    CHANNELS.forEach((channel, i) => {
      if (this.visible[i]) this.drawChannel(ctx, plot, channel, i);
    });
    if (this.hover) this.drawHover(ctx, plot);
  }

  drawFrame(ctx, plot) {
    ctx.fillStyle = "#fbfcfd";
    ctx.fillRect(0, 0, this.canvas.clientWidth, this.canvas.clientHeight);
    ctx.strokeStyle = "#d9e0e6";
    ctx.lineWidth = 1;
    ctx.strokeRect(plot.left, plot.top, plot.width, plot.height);
    ctx.font = "12px system-ui";
    ctx.fillStyle = "#687782";
    ctx.textAlign = "right";
    ctx.textBaseline = "middle";
    for (let i = 0; i <= 4; i += 1) {
      const y = plot.top + (plot.height * i) / 4;
      ctx.strokeStyle = i === 4 ? "#c9d2da" : "#edf2f6";
      ctx.beginPath();
      ctx.moveTo(plot.left, y);
      ctx.lineTo(plot.right, y);
      ctx.stroke();
      ctx.fillText(`${Math.round(200 - i * 50)}`, plot.left - 9, y);
    }
    ctx.textAlign = "center";
    ctx.textBaseline = "top";
    const d = this.domain();
    const tickCount = Math.min(30, Math.max(5, Math.floor(plot.width / 180)));
    for (let i = 0; i <= tickCount; i += 1) {
      const x = plot.left + (plot.width * i) / tickCount;
      const point = Math.round(d.start + (d.count * i) / tickCount);
      ctx.strokeStyle = "#edf2f6";
      ctx.beginPath();
      ctx.moveTo(x, plot.top);
      ctx.lineTo(x, plot.bottom);
      ctx.stroke();
      ctx.fillStyle = "#687782";
      ctx.fillText(`${(point * TSCALE).toFixed(0)} s`, x, plot.bottom + 12);
    }
  }

  drawChannel(ctx, plot, channel, channelIndex) {
    const d = this.domain();
    if (d.end <= d.start) return;
    ctx.save();
    ctx.beginPath();
    ctx.rect(plot.left, plot.top, plot.width, plot.height);
    ctx.clip();
    ctx.strokeStyle = channel.color;
    ctx.lineWidth = channelIndex < 2 ? 1.8 : 1.4;
    ctx.beginPath();
    let moved = false;
    const step = Math.max(1, Math.floor((d.end - d.start) / Math.max(plot.width * 2, 1)));
    for (let i = d.start; i < d.end; i += step) {
      const point = this.points[i];
      if (!point) continue;
      const x = plot.left + ((i - d.start) / Math.max(d.count - 1, 1)) * plot.width;
      const y = scaleY(displayChannelValue(this.points, i, channelIndex), channel, plot);
      if (!moved) {
        ctx.moveTo(x, y);
        moved = true;
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
    ctx.restore();
  }

  drawMarkers(ctx, plot) {
    const d = this.domain();
    ctx.save();
    ctx.beginPath();
    ctx.rect(plot.left, plot.top, plot.width, plot.height);
    ctx.clip();
    for (const marker of this.markers) {
      if (marker.point < d.start || marker.point >= d.end) continue;
      const x = plot.left + ((marker.point - d.start) / Math.max(d.count - 1, 1)) * plot.width;
      ctx.strokeStyle = "rgba(23,32,38,0.28)";
      ctx.beginPath();
      ctx.moveTo(x, plot.top);
      ctx.lineTo(x, plot.bottom);
      ctx.stroke();
      ctx.save();
      ctx.translate(x + 5, plot.top + 12);
      ctx.rotate(-Math.PI / 2);
      ctx.fillStyle = "#687782";
      ctx.font = "700 11px system-ui";
      ctx.fillText(marker.text, 0, 0);
      ctx.restore();
    }
    ctx.restore();
  }

  drawHover(ctx, plot) {
    const d = this.domain();
    const x = plot.left + ((this.hover.index - d.start) / Math.max(d.count - 1, 1)) * plot.width;
    ctx.save();
    ctx.strokeStyle = "rgba(15,122,122,0.74)";
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.moveTo(x, plot.top);
    ctx.lineTo(x, plot.bottom);
    ctx.stroke();

    CHANNELS.forEach((channel, i) => {
      if (!this.visible[i]) return;
      const y = scaleY(displayChannelValue(this.points, this.hover.index, i), channel, plot);
      ctx.strokeStyle = channel.color;
      ctx.beginPath();
      ctx.moveTo(plot.left, y);
      ctx.lineTo(plot.right, y);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle = channel.color;
      ctx.beginPath();
      ctx.arc(x, y, 3.5, 0, Math.PI * 2);
      ctx.fill();
      ctx.setLineDash([4, 4]);
    });
    ctx.restore();
  }
}

function scaleY(value, channel, plot) {
  const y = plot.bottom - ((value - channel.min) / (channel.max - channel.min)) * plot.height;
  return clamp(y, plot.top, plot.bottom);
}

function displayChannelValue(points, index, channelIndex) {
  const point = points[index];
  if (!point) return null;
  if (channelIndex !== HR_CHANNEL_INDEX) return point[channelIndex];

  const stableIndex = index % 2 === 0 ? index + 1 : index;
  const stablePoint = points[stableIndex];
  const stableValue = stablePoint?.[channelIndex];
  return Number.isFinite(stableValue) ? stableValue : point[channelIndex];
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function formatDose(dose) {
  if (dose < 0.001) return `${(dose * 1e6).toFixed(0)} ng/kg`;
  if (dose < 1) return `${(dose * 1e3).toFixed(dose < 0.01 ? 1 : 0)} ug/kg`;
  return `${dose.toFixed(dose < 10 ? 1 : 0)} mg/kg`;
}

function formatChannelValue(value, channelIndex, units) {
  if (value === null) return "-";
  const decimals = channelIndex === HR_CHANNEL_INDEX ? 0 : 1;
  return `${value.toFixed(decimals)}${units ? ` ${units}` : ""}`;
}

function doseOptions(drug) {
  const values = [];
  let dose = drug.minDose;
  while (dose <= drug.maxDose * 1.0001 && values.length < 40) {
    for (const factor of [1, 2, 5]) {
      const value = dose * factor;
      if (value <= drug.maxDose * 1.0001) values.push(value);
    }
    dose *= 10;
  }
  return values;
}

function parseHeader(buffer) {
  const bytes = new Uint8Array(buffer.slice(0, HEADER_BYTES));
  let text = "";
  for (const byte of bytes) {
    if (byte === 0) break;
    text += String.fromCharCode(byte);
  }
  const map = new Map();
  for (const line of text.split(/\r?\n/)) {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) map.set(match[1], match[2]);
  }
  return map;
}

function parseRatFile(buffer) {
  const header = parseHeader(buffer);
  const npoints = Number.parseInt(header.get("NPOINTS") || "0", 10);
  const view = new DataView(buffer, HEADER_BYTES);
  const points = [];
  for (let i = 0; i < npoints; i += 1) {
    const row = [];
    for (let ch = 0; ch < NUM_CHANNELS; ch += 1) {
      const raw = view.getInt16((i * NUM_CHANNELS + ch) * 2, true);
      row.push(raw * CHANNELS[ch].scale);
    }
    points.push(row);
  }
  const markers = [];
  const nmarkers = Number.parseInt(header.get("NMARKERS") || "0", 10);
  for (let i = 0; i < nmarkers; i += 1) {
    markers.push({
      point: Number.parseInt(header.get(`MKP${i}`) || header.get(`MKPOINT${i}`) || "0", 10),
      text: header.get(`MKT${i}`) || header.get(`MKTEXT${i}`) || "",
    });
  }
  return { points, markers, pithed: header.get("PITHED") !== "F" };
}

const I18N = {
  ja: {
    eyebrow: "ラット心血管系シミュレーション",
    newExperiment: "新規実験",
    start: "開始",
    stop: "停止",
    recording: "記録中",
    pithed: "脊髄破壊",
    normal: "正常",
    sample: "サンプル",
    sampleNone: "未選択",
    sampleAch: "アセチルコリン + アトロピン",
    sampleAgonist: "アドレナリン受容体作動薬",
    sampleAntagonist: "アドレナリン受容体遮断薬",
    sampleRenal: "腎神経刺激 + ロサルタン",
    sampleVagus: "迷走神経 + アトロピン",
    speed: "速度",
    speed1x: "等倍（実機準拠）",
    loadRat: ".rat 読込",
    saveRat: "保存",
    window: "表示幅",
    fit: "全体",
    currentValues: "現在値",
    drugs: "薬物",
    agonist: "作動薬",
    antagonist: "遮断薬",
    unknown: "未知薬",
    dose: "用量",
    inject: "投与",
    injectAgonist: "作動薬を投与",
    injectAntagonist: "遮断薬を投与",
    injectUnknown: "未知薬を投与",
    nerveStim: "神経刺激",
    stimVessels: "交感神経（血管）",
    stimHeart: "交感神経（心臓）",
    stimAdrenal: "交感神経（副腎）",
    stimRenal: "腎神経",
    stimVagus: "迷走神経",
    channels: "チャンネル",
    visibleRange: "表示範囲",
    points: "点数",
    model: "モデル",
    relative: "相対値",
    min: "最小",
    max: "最大",
    windowLabel: "表示幅",
    emptyChart: "「開始」を押すか .rat ファイルを読み込んでください",
    ratDied: "ラットが死亡しました",
    vitalsAbp: "動脈圧 (収縮/拡張)",
    vitalsMean: "平均",
    vitalsHr: "心拍数",
    vitalsLvp: "左室圧 (ピーク)",
    vitalsVbp: "静脈圧",
    noData: "—",
  },
  en: {
    eyebrow: "Rat Cardiovascular System Simulation",
    newExperiment: "New experiment",
    start: "Start",
    stop: "Stop",
    recording: "Recording",
    pithed: "Pithed",
    normal: "Normal",
    sample: "Sample",
    sampleNone: "None",
    sampleAch: "Acetylcholine + Atropine",
    sampleAgonist: "Adrenoceptor agonists",
    sampleAntagonist: "Adrenoceptor antagonists",
    sampleRenal: "Renal nerve stim + Losartan",
    sampleVagus: "Vagus nerve + Atropine",
    speed: "Speed",
    speed1x: "1× (true to app)",
    loadRat: "Load .rat",
    saveRat: "Save",
    window: "Window",
    fit: "Fit",
    currentValues: "Current values",
    drugs: "Drugs",
    agonist: "Agonist",
    antagonist: "Antagonist",
    unknown: "Unknown",
    dose: "Dose",
    inject: "Inject",
    injectAgonist: "Inject agonist",
    injectAntagonist: "Inject antagonist",
    injectUnknown: "Inject unknown",
    nerveStim: "Nerve stimulation",
    stimVessels: "Sympathetic (vessels)",
    stimHeart: "Sympathetic (heart)",
    stimAdrenal: "Sympathetic (adrenal)",
    stimRenal: "Renal nerve",
    stimVagus: "Vagus nerve",
    channels: "Channels",
    visibleRange: "Visible range",
    points: "Points",
    model: "Model",
    relative: "relative",
    min: "Min",
    max: "Max",
    windowLabel: "window",
    emptyChart: "Press Start or load a .rat file",
    ratDied: "Your rat has died",
    vitalsAbp: "Arterial BP (sys/dia)",
    vitalsMean: "mean",
    vitalsHr: "Heart rate",
    vitalsLvp: "LV pressure (peak)",
    vitalsVbp: "Venous BP",
    noData: "—",
  },
};

const state = {
  simulation: new RatSimulation(),
  running: false,
  renderer: null,
  raf: 0,
  lang: "ja",
  speed: 1,
  stepAccumulator: 0,
  lastTick: null,
};

function t(key) {
  const table = I18N[state.lang] || I18N.ja;
  return table[key] ?? I18N.ja[key] ?? key;
}

// step() など t がローカル名で隠れるスコープから翻訳を呼ぶための別名ヘルパー
function translate(key) {
  return t(key);
}

function applyTranslations() {
  document.documentElement.lang = state.lang;
  document.title = "RatCVS";
  for (const el of document.querySelectorAll("[data-i18n]")) {
    el.textContent = t(el.dataset.i18n);
  }
  document.querySelectorAll(".lang-button").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.lang === state.lang);
  });
  $("#toggleRun").textContent = state.running ? t("stop") : t("start");
  $("#modeLabel").textContent = modelLabel();
  refreshDynamicLabels();
}

function refreshDynamicLabels() {
  // 言語に依存する動的生成要素を再描画する
  renderLegend();
  if (state.renderer) {
    updateGraphLabels();
    updateVitals();
    state.renderer.draw();
  }
}

function setLanguage(lang) {
  if (!I18N[lang]) return;
  state.lang = lang;
  try { localStorage.setItem("ratcvs.lang", lang); } catch (e) { /* ignore */ }
  applyTranslations();
}

function modelLabel() {
  return state.simulation.pithed ? t("pithed") : t("normal");
}

const DOSE_SELECT_FOR = {
  agonistSelect: "agonistDose",
  antagonistSelect: "antagonistDose",
  unknownSelect: "unknownDose",
};

function renderLegend() {
  const legend = $("#channelLegend");
  if (!legend) return;
  legend.innerHTML = CHANNELS.map((channel, i) => {
    const off = state.renderer && state.renderer.visible[i] === false;
    const units = channel.units ? `<small>${channel.units}</small>` : "";
    return `
      <button type="button" class="legend-chip${off ? " is-off" : ""}" data-channel="${i}"
        aria-pressed="${off ? "false" : "true"}">
        <span class="channel-swatch" style="background:${channel.color}"></span>${channel.name}${units}
      </button>
    `;
  }).join("");
}

function toggleChannel(index) {
  if (!Number.isInteger(index) || !state.renderer) return;
  state.renderer.visible[index] = !state.renderer.visible[index];
  renderLegend();
  state.renderer.draw();
  updateRangeStats();
}

function populateControls() {
  renderLegend();
  $("#channelLegend").addEventListener("click", (event) => {
    const chip = event.target.closest(".legend-chip");
    if (chip) toggleChannel(Number(chip.dataset.channel));
  });

  const sim = state.simulation;
  const agonists = sim.drugs.slice(0, sim.lastAgonist + 1);
  const antagonists = sim.drugs.slice(sim.lastAgonist + 1, sim.lastAntagonist + 1);
  const unknowns = sim.drugs.slice(sim.lastAntagonist + 1, sim.lastUnknown + 1);
  fillDrugSelect($("#agonistSelect"), agonists, 0);
  fillDrugSelect($("#antagonistSelect"), antagonists, sim.lastAgonist + 1);
  fillDrugSelect($("#unknownSelect"), unknowns, sim.lastAntagonist + 1);
  updateDoseSelect($("#agonistSelect"), $("#agonistDose"));
  updateDoseSelect($("#antagonistSelect"), $("#antagonistDose"));
  updateDoseSelect($("#unknownSelect"), $("#unknownDose"));
}

function fillDrugSelect(select, drugs, offset) {
  select.innerHTML = drugs.map((drug, i) => `<option value="${offset + i}">${drug.name}</option>`).join("");
  select.addEventListener("change", () => {
    updateDoseSelect(select, $(`#${DOSE_SELECT_FOR[select.id]}`));
  });
}

function updateDoseSelect(drugSelect, doseSelect) {
  const drug = state.simulation.drugs[Number(drugSelect.value)];
  doseSelect.innerHTML = doseOptions(drug).map((dose) => `<option value="${dose}">${formatDose(dose)}</option>`).join("");
}

function bindUi() {
  $("#toggleRun").addEventListener("click", () => setRunning(!state.running));
  $("#newExperiment").addEventListener("click", () => {
    setRunning(false);
    state.simulation.reset();
    state.simulation.pithed = $("input[name='model']:checked").value === "pithed";
    warmUp();
    state.renderer.start = 0;
    syncData();
  });
  document.querySelectorAll("input[name='model']").forEach((input) => {
    input.addEventListener("change", () => {
      state.simulation.pithed = input.value === "pithed";
      $("#modeLabel").textContent = modelLabel();
    });
  });
  document.querySelectorAll(".lang-button").forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.lang));
  });
  $("#speedSelect").addEventListener("change", (event) => {
    state.speed = Number(event.target.value) || 1;
  });
  $("#saveRecording").addEventListener("click", saveRecording);
  $("#injectAgonist").addEventListener("click", () => injectFrom($("#agonistSelect"), $("#agonistDose")));
  $("#injectAntagonist").addEventListener("click", () => injectFrom($("#antagonistSelect"), $("#antagonistDose")));
  $("#injectUnknown").addEventListener("click", () => injectFrom($("#unknownSelect"), $("#unknownDose")));
  document.querySelectorAll(".stim").forEach((button) => {
    button.addEventListener("click", () => {
      state.simulation.stimulate(button.dataset.stim);
      syncData();
    });
  });
  $("#zoomOut").addEventListener("click", () => setWindowSize(state.renderer.windowSize * 1.35));
  $("#zoomIn").addEventListener("click", () => setWindowSize(state.renderer.windowSize / 1.35));
  $("#fitGraph").addEventListener("click", () => setWindowSize(Math.max(4000, state.simulation.points.length || 4000), 0));
  $("#zoomRange").addEventListener("input", (event) => setWindowSize(Number(event.target.value)));
  $("#chartScroll").addEventListener("scroll", () => {
    state.renderer.updateStartFromScroll();
    state.renderer.draw();
    updateGraphLabels();
  });
  $("#chartScroll").addEventListener("wheel", (event) => {
    if (Math.abs(event.deltaX) > Math.abs(event.deltaY) || state.simulation.points.length === 0) return;
    event.preventDefault();
    const anchorIndex = state.renderer.indexAtClientX(event.clientX);
    const zoomFactor = Math.exp(event.deltaY * 0.001);
    setWindowSizeAtAnchor(state.renderer.windowSize * zoomFactor, anchorIndex, event.clientX);
  }, { passive: false });
  $("#fileInput").addEventListener("change", async (event) => {
    const [file] = event.target.files;
    if (!file) return;
    loadRecording(await file.arrayBuffer());
  });
  $("#sampleSelect").addEventListener("change", async (event) => {
    if (!event.target.value) return;
    const response = await fetch(event.target.value);
    const buffer = await response.arrayBuffer();
    loadRecording(buffer);
  });
}

function injectFrom(drugSelect, doseSelect) {
  state.simulation.inject(Number(drugSelect.value), Number(doseSelect.value));
  syncData();
}

function loadRecording(buffer) {
  const recording = parseRatFile(buffer);
  state.simulation.reset();
  state.simulation.points = recording.points;
  state.simulation.markers = recording.markers;
  state.simulation.pithed = recording.pithed;
  document.querySelector(`input[name='model'][value='${recording.pithed ? "pithed" : "normal"}']`).checked = true;
  $("#modeLabel").textContent = modelLabel();
  state.renderer.start = 0;
  setRunning(false);
  syncData();
}

// 本体は Timer.Interval=50ms で 1 秒あたり 20 回 step を呼ぶ（RATMAIN.dfm）。
// 等倍(speed=1)で本体と同じ進行速度になるよう、実時間ベースで step を実行する。
const BASE_STEPS_PER_SECOND = 20;

function setRunning(running) {
  state.running = running;
  $("#toggleRun").textContent = running ? t("stop") : t("start");
  $("#toggleRun").classList.toggle("primary", true);
  state.lastTick = null;
  state.stepAccumulator = 0;
  if (running) state.raf = requestAnimationFrame(runLoop);
  else cancelAnimationFrame(state.raf);
}

function runLoop(now) {
  if (!state.running) return;
  if (state.lastTick === null) state.lastTick = now;
  // タブ復帰時の大量キャッチアップを避けるため経過を制限
  const elapsed = Math.min(now - state.lastTick, 250);
  state.lastTick = now;
  state.stepAccumulator += (elapsed / 1000) * BASE_STEPS_PER_SECOND * state.speed;
  let steps = Math.floor(state.stepAccumulator);
  state.stepAccumulator -= steps;
  steps = Math.min(steps, 600);

  if (steps > 0) {
    const wasFollowingEnd = state.renderer.start + state.renderer.windowSize >= state.simulation.points.length - 40;
    for (let i = 0; i < steps; i += 1) state.simulation.step();
    if (wasFollowingEnd) {
      state.renderer.start = Math.max(0, state.simulation.points.length - state.renderer.windowSize);
    }
    syncData();
  }
  state.raf = requestAnimationFrame(runLoop);
}

function syncData() {
  state.renderer.setData(state.simulation.points, state.simulation.markers);
  $("#pointCount").textContent = state.simulation.points.length.toLocaleString();
  $("#modeLabel").textContent = modelLabel();
  syncGraphViewport();
  updateVitals();
}

function liveVitals() {
  const points = state.simulation.points;
  if (points.length === 0) return null;
  const window = Math.min(points.length, 240);
  const start = points.length - window;
  let sys = -Infinity;
  let dia = Infinity;
  let lvp = -Infinity;
  let vbpSum = 0;
  let vbpCount = 0;
  for (let i = start; i < points.length; i += 1) {
    const point = points[i];
    if (!point) continue;
    sys = Math.max(sys, point[0]);
    dia = Math.min(dia, point[0]);
    lvp = Math.max(lvp, point[1]);
    vbpSum += point[2];
    vbpCount += 1;
  }
  const hr = displayChannelValue(points, points.length - 1, HR_CHANNEL_INDEX);
  return {
    sys: Number.isFinite(sys) ? sys : null,
    dia: Number.isFinite(dia) ? dia : null,
    mean: Number.isFinite(sys) && Number.isFinite(dia) ? dia + (sys - dia) / 3 : null,
    hr: Number.isFinite(hr) ? hr : null,
    lvp: Number.isFinite(lvp) ? lvp : null,
    vbp: vbpCount > 0 ? vbpSum / vbpCount : null,
  };
}

function updateVitals() {
  const container = $("#liveVitals");
  if (!container) return;
  const v = liveVitals();
  const num = (value, digits = 0) => (value === null || value === undefined ? t("noData") : value.toFixed(digits));
  container.innerHTML = `
    <div class="vitals-item">
      <span style="color:${CHANNELS[0].color}">${t("vitalsAbp")}</span>
      <strong>${v ? `${num(v.sys)}/${num(v.dia)}` : t("noData")}<small> mmHg</small></strong>
      <small>${t("vitalsMean")} ${v ? num(v.mean) : t("noData")}</small>
    </div>
    <div class="vitals-item">
      <span style="color:${CHANNELS[4].color}">${t("vitalsHr")}</span>
      <strong>${v ? num(v.hr) : t("noData")}<small> BPM</small></strong>
    </div>
    <div class="vitals-item">
      <span style="color:${CHANNELS[1].color}">${t("vitalsLvp")}</span>
      <strong>${v ? num(v.lvp) : t("noData")}<small> mmHg</small></strong>
    </div>
    <div class="vitals-item">
      <span style="color:${CHANNELS[2].color}">${t("vitalsVbp")}</span>
      <strong>${v ? num(v.vbp, 1) : t("noData")}<small> mmHg</small></strong>
    </div>
  `;
}

function saveRecording() {
  const sim = state.simulation;
  const points = sim.points;
  const markers = sim.markers || [];
  let header = "";
  header += `NPOINTS=${points.length}\r\n`;
  header += `NMARKERS=${markers.length}\r\n`;
  header += `PITHED=${sim.pithed ? "T" : "F"}\r\n`;
  markers.forEach((marker, i) => {
    header += `MKP${i}=${marker.point}\r\n`;
    header += `MKT${i}=${marker.text}\r\n`;
  });
  const buffer = new ArrayBuffer(HEADER_BYTES + points.length * NUM_CHANNELS * 2);
  const bytes = new Uint8Array(buffer);
  for (let i = 0; i < header.length && i < HEADER_BYTES; i += 1) {
    bytes[i] = header.charCodeAt(i) & 0xff;
  }
  const view = new DataView(buffer, HEADER_BYTES);
  for (let i = 0; i < points.length; i += 1) {
    const row = points[i];
    for (let ch = 0; ch < NUM_CHANNELS; ch += 1) {
      const raw = clamp(Math.round((row[ch] || 0) / CHANNELS[ch].scale), -32768, 32767);
      view.setInt16((i * NUM_CHANNELS + ch) * 2, raw, true);
    }
  }
  const blob = new Blob([buffer], { type: "application/octet-stream" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "ratcvs-recording.rat";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function setWindowSize(nextWindowSize, nextStart = null) {
  const points = Math.max(state.simulation.points.length, 1);
  const minWindow = 250;
  const maxWindow = Math.max(12000, points);
  const oldCenter = state.renderer.start + state.renderer.windowSize / 2;
  state.renderer.windowSize = Math.round(clamp(nextWindowSize, minWindow, maxWindow));
  state.renderer.start = nextStart === null
    ? Math.round(oldCenter - state.renderer.windowSize / 2)
    : nextStart;
  syncGraphViewport();
  state.renderer.draw();
}

function setWindowSizeAtAnchor(nextWindowSize, anchorIndex, anchorClientX) {
  const points = Math.max(state.simulation.points.length, 1);
  const minWindow = 250;
  const maxWindow = Math.max(12000, points);
  state.renderer.windowSize = Math.round(clamp(nextWindowSize, minWindow, maxWindow));
  $("#zoomRange").max = String(Math.max(12000, state.simulation.points.length || 12000));
  $("#zoomRange").value = String(Math.min(state.renderer.windowSize, Number($("#zoomRange").max)));
  state.renderer.updateCanvasWidth();
  state.renderer.resize();
  state.renderer.scrollToIndexAtClientX(anchorIndex, anchorClientX);
  state.renderer.draw();
  updateGraphLabels();
}

function syncGraphViewport() {
  const points = state.simulation.points.length;
  const maxStart = Math.max(0, points - state.renderer.windowSize);
  state.renderer.start = clamp(state.renderer.start, 0, maxStart);
  $("#zoomRange").max = String(Math.max(12000, points || 12000));
  $("#zoomRange").value = String(Math.min(state.renderer.windowSize, Number($("#zoomRange").max)));
  state.renderer.updateCanvasWidth();
  state.renderer.resize();
  state.renderer.scrollToStart(state.renderer.start);
  state.renderer.draw();
  updateGraphLabels();
}

function updateGraphLabels() {
  const range = state.renderer.visiblePointRange();
  const start = range.start * TSCALE;
  const end = range.end * TSCALE;
  const visible = state.renderer.windowSize * TSCALE;
  $("#timeRangeLabel").textContent = `${start.toFixed(1)} s - ${end.toFixed(1)} s / ${t("windowLabel")} ${visible.toFixed(1)} s`;
  updateRangeStats();
}

function updateRangeStats() {
  const container = $("#visibleRangeStats");
  if (!container || !state.renderer) return;
  const stats = state.renderer.visibleRangeStats();
  container.innerHTML = stats.map(({ channel, visible, min, max }, index) => `
    <div class="range-stat-item${visible ? "" : " is-muted"}">
      <div class="range-stat-name">
        <span class="channel-swatch" style="background:${channel.color}"></span>${channel.name}
      </div>
      <div class="range-stat-value">
        <span>${t("min")}</span>
        <strong>${formatChannelValue(min, index, channel.units)}</strong>
      </div>
      <div class="range-stat-value">
        <span>${t("max")}</span>
        <strong>${formatChannelValue(max, index, channel.units)}</strong>
      </div>
    </div>
  `).join("");
}

function warmUp() {
  // 表示前に定常状態まで進めて初期過渡応答を隠す
  for (let i = 0; i < 700; i += 1) state.simulation.step();
}

function boot() {
  try {
    const saved = localStorage.getItem("ratcvs.lang");
    if (saved && I18N[saved]) state.lang = saved;
  } catch (e) { /* ignore */ }
  state.renderer = new ChartRenderer($("#chartCanvas"), $("#hoverReadout"), $("#chartScroll"));
  populateControls();
  bindUi();
  warmUp();
  applyTranslations();
  syncData();
}

boot();
