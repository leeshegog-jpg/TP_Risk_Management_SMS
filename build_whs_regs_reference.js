'use strict';
/**
 * build_whs_regs_reference.js
 * Generates WHS_Legislation_Reference.docx — a structured reference guide for
 * the Model Work Health and Safety Act 2011 and WHS Regulations 2017 (Cth/Aus).
 *
 * Usage:  node build_whs_regs_reference.js
 * Output: WHS_Legislation_Reference.docx
 */

const {
  Document, Packer, Paragraph, Table, TableRow, TableCell,
  TextRun, HeadingLevel, AlignmentType, WidthType, ShadingType,
  TableLayoutType, BorderStyle, VerticalAlign, UnderlineType,
} = require('docx');
const fs = require('fs');

// ── Shared styles ─────────────────────────────────────────────────────────────
const BORDER = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };
const NAVY = '1F3864';
const NAVY_MID = '2E4C8B';
const LIGHT_BLUE = 'EBF2FF';
const STRIPE = 'F3F4F6';

function hCell(text, fill = NAVY, width = null) {
  const opts = {
    shading: { fill, type: ShadingType.CLEAR, color: 'auto' },
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.LEFT,
      children: [new TextRun({ text, bold: true, color: 'FFFFFF', size: 18 })],
    })],
  };
  if (width) opts.width = { size: width, type: WidthType.PERCENTAGE };
  return new TableCell(opts);
}

function td(text, bold = false, fill = null, color = '111827', align = AlignmentType.LEFT) {
  return new TableCell({
    shading: fill ? { fill, type: ShadingType.CLEAR, color: 'auto' } : undefined,
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: align,
      children: [new TextRun({ text, bold, color, size: 18 })],
    })],
  });
}

function tdMulti(runs) {
  return new TableCell({
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({ children: runs })],
  });
}

function row(cells, isAlt = false) {
  return new TableRow({ children: cells.map((c, i) => typeof c === 'string' ? td(c, false, isAlt ? STRIPE : null) : c) });
}

function headerRow(...labels) {
  return new TableRow({ tableHeader: true, children: labels.map(l => hCell(l)) });
}

function h(text, level = HeadingLevel.HEADING_1) {
  return new Paragraph({ text, heading: level, spacing: { before: 400, after: 160 } });
}

function p(text) {
  return new Paragraph({ children: [new TextRun({ text, size: 20 })], spacing: { after: 140 } });
}

function spacer() { return new Paragraph({ text: '', spacing: { after: 240 } }); }

function bullet(text) {
  return new Paragraph({
    children: [new TextRun({ text, size: 20 })],
    bullet: { level: 0 },
    spacing: { after: 80 },
  });
}

// ── Data ───────────────────────────────────────────────────────────────────────

// Section 1 — Key duties quick-reference
const KEY_DUTIES = [
  {
    dutyHolder: 'PCBU\n(Person Conducting a Business or Undertaking)',
    section: 'ss 17–20, 22–26',
    duty: 'Ensure the health and safety of workers and others affected by the work, so far as is reasonably practicable (SFARP). Primary duty of care.',
    examples: 'Safe systems of work; plant/substances; workplace facilities; information/training/supervision; monitoring health/conditions.',
  },
  {
    dutyHolder: 'Officers\n(e.g. Directors, CEOs, Senior Managers)',
    section: 's 27',
    duty: 'Exercise due diligence to ensure the PCBU complies with its duties. Proactive obligation — cannot be delegated.',
    examples: 'Acquire WHS knowledge; understand operations\' hazards; ensure resources/processes; verify WHS reporting and response.',
  },
  {
    dutyHolder: 'Workers',
    section: 's 28',
    duty: 'Take reasonable care for own health and safety; not adversely affect others; comply with lawful WHS instructions.',
    examples: 'Follow safe work procedures; use PPE; report hazards and incidents; cooperate with WHS management measures.',
  },
  {
    dutyHolder: 'Designers of Plant/Structures/Substances',
    section: 'ss 22–23',
    duty: 'Ensure the design is, SFARP, without risks to health and safety when used for its intended purpose.',
    examples: 'Design review for foreseeable risks; provide safety information with the design; consult with manufacturers.',
  },
  {
    dutyHolder: 'Manufacturers',
    section: 's 23',
    duty: 'Ensure plant, substances or structures manufactured are, SFARP, without risks to health and safety.',
    examples: 'Carry out or commission testing; provide adequate information; notify of safety risks discovered post-supply.',
  },
  {
    dutyHolder: 'Importers & Suppliers',
    section: 'ss 24–25',
    duty: 'Ensure imported/supplied plant, substances or structures are, SFARP, without risks to health and safety.',
    examples: 'Inspect and test; ensure designer/manufacturer has complied; provide safety information.',
  },
  {
    dutyHolder: 'Persons with Management or Control of a Workplace',
    section: 's 20',
    duty: 'Ensure, SFARP, that the workplace and its means of entry/exit are without risks to health and safety.',
    examples: 'Maintain safe access/egress; coordinate with other PCBUs on shared hazards.',
  },
];

// Section 2 — Penalty tiers
const PENALTIES = [
  {
    category: 'Category 1',
    description: 'Gross negligence or reckless conduct causing risk of death or serious injury/illness.',
    individual: '$300,000\nor 5 years imprisonment, or both',
    pcbu_officer: '$300,000\nor 5 years imprisonment, or both',
    body_corporate: '$3,000,000',
    fill: 'C00000',
  },
  {
    category: 'Category 2',
    description: 'Failure to comply with a duty that exposes an individual to risk of death or serious injury/illness.',
    individual: '$150,000',
    pcbu_officer: '$150,000',
    body_corporate: '$1,500,000',
    fill: 'FF7C00',
  },
  {
    category: 'Category 3',
    description: 'Failure to comply with a duty (not involving risk of death or serious injury/illness).',
    individual: '$50,000',
    pcbu_officer: '$50,000',
    body_corporate: '$500,000',
    fill: 'FFC000',
  },
];

// Section 3 — Key Act sections quick-reference
const ACT_SECTIONS = [
  { ref: 'ss 1–4',   topic: 'Preliminary — objects, definitions, scope' },
  { ref: 's 5',      topic: 'Definition of "worker" (broad — includes contractors, volunteers)' },
  { ref: 's 8',      topic: 'Definition of PCBU — includes company, partnership, association, sole trader' },
  { ref: 'ss 17–20', topic: 'Primary duties of PCBUs — safe work, workplace, plant, substances, systems' },
  { ref: 's 21',     topic: 'Duty of PCBU to remote/isolated workers' },
  { ref: 'ss 22–26', topic: 'Designer, manufacturer, importer, supplier and installer duties' },
  { ref: 's 27',     topic: 'Officer due diligence duty (6 elements)' },
  { ref: 's 28',     topic: 'Worker duties — self-care, cooperation, following instructions' },
  { ref: 's 29',     topic: 'Other person at the workplace — must not endanger others' },
  { ref: 'ss 30–31', topic: 'Meaning of "reasonably practicable"' },
  { ref: 'ss 34–39', topic: 'Consultation — duty to consult workers; who and when' },
  { ref: 'ss 47–73', topic: 'Representation — Health and Safety Representatives (HSRs)' },
  { ref: 'ss 75–79', topic: 'Health and Safety Committees' },
  { ref: 'ss 81–82', topic: 'Provisional Improvement Notices (PINs)' },
  { ref: 's 117',    topic: 'Duty to notify regulator of notifiable incidents' },
  { ref: 'ss 118–119', topic: 'Preservation of incident site' },
  { ref: 's 120',    topic: 'Definition of notifiable incident (death, serious injury/illness, dangerous incident)' },
  { ref: 's 122',    topic: 'Record-keeping of notifiable incidents (minimum 5 years)' },
  { ref: 'ss 138–155', topic: 'Inspectors — powers of entry, inspection, evidence, and directions' },
  { ref: 'ss 164–168', topic: 'Improvement Notices issued by inspectors' },
  { ref: 'ss 171–174', topic: 'Prohibition Notices — immediate cessation of unsafe activity' },
  { ref: 'ss 191–229', topic: 'Investigations, enforceable undertakings, and prosecution' },
  { ref: 'ss 230–244', topic: 'Offences and penalties (Categories 1, 2, 3)' },
  { ref: 'ss 270–271', topic: 'Work health and safety entry permits — right-of-entry provisions' },
];

// Section 4 — WHS Regulations 2017 key parts
const REGS = [
  { part: 'Part 2.1 — Managing Risks (rr 33–38)',      summary: 'Duty to manage WHS risks using the hierarchy of controls. Requires hazard identification, risk assessment, control implementation, and review.' },
  { part: 'Part 2.2 — Consultation (rr 46–50)',         summary: 'When and how to consult workers on risk-management decisions; obligations when multiple PCBUs share a workplace.' },
  { part: 'Part 3.1 — Plant (rr 193–253)',              summary: 'Registration of plant designs and plant items; operating plant safely; documentation requirements.' },
  { part: 'Part 3.2 — Hazardous Chemicals (rr 328–388)',summary: 'SDS management, labelling, storage, manifest threshold quantities, inventory registers, and prohibited/restricted substances.' },
  { part: 'Part 3.3 — Confined Spaces (rr 64–72)',     summary: 'Entry permits, atmospheric testing, rescue planning, and communication requirements for confined space work.' },
  { part: 'Part 3.4 — Falls (rr 73–82)',               summary: 'Fall prevention hierarchy — elimination, fall arrest, administrative controls — for work at heights above 2 m (general).' },
  { part: 'Part 3.5 — Electrical Safety (rr 140–165)', summary: 'RCD requirements, energised work, testing and tagging of electrical equipment, and electrical installations.' },
  { part: 'Part 4 — Asbestos (rr 415–476)',            summary: 'Asbestos management plans, identification, removal licences (Class A / Class B), health monitoring, and air monitoring.' },
  { part: 'Part 5 — Licensing (rr 477–543)',           summary: 'High-risk work licences (HRWLs) — classes, applications, assessment, renewal, and conduct of licensed high-risk work.' },
  { part: 'Part 6 — Reporting & Notification (rr 685–693)', summary: 'Notifiable incident reporting timelines (immediate notification; written report within 48 hours) and incident register obligations.' },
  { part: 'Part 7 — General (rr 694–730)',             summary: 'First aid requirements, emergency plans, remote/isolated work plans, and worker health monitoring obligations.' },
];

// ── Build tables ───────────────────────────────────────────────────────────────

function buildDutiesTable() {
  const hdr = new TableRow({
    tableHeader: true,
    children: [
      hCell('Duty Holder', NAVY, 22),
      hCell('Section(s)', NAVY, 12),
      hCell('Core Duty', NAVY, 38),
      hCell('Examples of Compliance', NAVY, 28),
    ],
  });
  const rows = KEY_DUTIES.map((d, i) => new TableRow({
    children: [
      td(d.dutyHolder, true, i % 2 ? STRIPE : null),
      td(d.section, false, i % 2 ? STRIPE : null, '1F3864'),
      td(d.duty, false, i % 2 ? STRIPE : null),
      td(d.examples, false, i % 2 ? STRIPE : null, '4B5563'),
    ],
  }));
  return new Table({ layout: TableLayoutType.FIXED, width: { size: 100, type: WidthType.PERCENTAGE }, rows: [hdr, ...rows] });
}

function buildPenaltiesTable() {
  const hdr = new TableRow({
    tableHeader: true,
    children: [
      hCell('Category', NAVY, 12),
      hCell('Description', NAVY, 32),
      hCell('Individual / Officer', NAVY, 20),
      hCell('PCBU / Officer (body)', NAVY, 18),
      hCell('Body Corporate', NAVY, 18),
    ],
  });
  const rows = PENALTIES.map(p => new TableRow({
    children: [
      new TableCell({
        shading: { fill: p.fill, type: ShadingType.CLEAR, color: 'auto' },
        borders: BORDERS,
        verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: p.category, bold: true, color: 'FFFFFF', size: 18 })] })],
      }),
      td(p.description),
      td(p.individual, true, null, '111827', AlignmentType.CENTER),
      td(p.pcbu_officer, true, null, '111827', AlignmentType.CENTER),
      td(p.body_corporate, true, null, 'C00000', AlignmentType.CENTER),
    ],
  }));
  return new Table({ layout: TableLayoutType.FIXED, width: { size: 100, type: WidthType.PERCENTAGE }, rows: [hdr, ...rows] });
}

function buildActTable() {
  const hdr = headerRow('Reference', 'Topic');
  const rows = ACT_SECTIONS.map((s, i) => new TableRow({
    children: [
      td(s.ref, true, i % 2 ? LIGHT_BLUE : null, NAVY),
      td(s.topic, false, i % 2 ? LIGHT_BLUE : null),
    ],
  }));
  return new Table({ layout: TableLayoutType.FIXED, width: { size: 100, type: WidthType.PERCENTAGE }, rows: [hdr, ...rows] });
}

function buildRegsTable() {
  const hdr = new TableRow({
    tableHeader: true,
    children: [hCell('Part / Regulation', NAVY, 35), hCell('Summary', NAVY, 65)],
  });
  const rows = REGS.map((r, i) => new TableRow({
    children: [
      td(r.part, true, i % 2 ? LIGHT_BLUE : null, NAVY),
      td(r.summary, false, i % 2 ? LIGHT_BLUE : null),
    ],
  }));
  return new Table({ layout: TableLayoutType.FIXED, width: { size: 100, type: WidthType.PERCENTAGE }, rows: [hdr, ...rows] });
}

// ── Hierarchy of controls table ────────────────────────────────────────────────
const HOC = [
  { rank: '1', control: 'Elimination',    desc: 'Remove the hazard entirely from the workplace.',             fill: '1A6B3C' },
  { rank: '2', control: 'Substitution',   desc: 'Replace the hazard with one that presents a lesser risk.',   fill: '2E7D32' },
  { rank: '3', control: 'Isolation',      desc: 'Separate the hazard from people (guarding, bunding, etc.)',  fill: '388E3C' },
  { rank: '4', control: 'Engineering',    desc: 'Reduce exposure through physical means (ventilation, interlocks, etc.)', fill: 'FBC02D' },
  { rank: '5', control: 'Administrative', desc: 'Change the way work is done (procedures, training, rotation).', fill: 'F57C00' },
  { rank: '6', control: 'PPE',            desc: 'Last resort — protect the individual only, not the source.', fill: 'C62828' },
];

function buildHOCTable() {
  const hdr = new TableRow({
    tableHeader: true,
    children: [hCell('Rank', NAVY, 8), hCell('Control Type', NAVY, 20), hCell('Description', NAVY, 72)],
  });
  const rows = HOC.map(h => new TableRow({
    children: [
      new TableCell({
        shading: { fill: h.fill, type: ShadingType.CLEAR, color: 'auto' },
        borders: BORDERS, verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: h.rank, bold: true, color: 'FFFFFF', size: 20 })] })],
      }),
      td(h.control, true, h.fill, 'FFFFFF'),
      td(h.desc),
    ],
  }));
  return new Table({ layout: TableLayoutType.FIXED, width: { size: 100, type: WidthType.PERCENTAGE }, rows: [hdr, ...rows] });
}

// ── Document assembly ──────────────────────────────────────────────────────────
const doc = new Document({
  creator: 'Control Effectiveness Calculator',
  title:   'WHS Legislation Reference',
  description: 'Model Work Health and Safety Act 2011 and WHS Regulations 2017 reference',
  styles: {
    default: {
      document: { run: { font: 'Calibri', size: 20 } },
    },
  },
  sections: [{
    properties: { page: { margin: { top: 720, bottom: 720, left: 1080, right: 1080 } } },
    children: [
      // ── Title ──
      new Paragraph({
        children: [new TextRun({ text: 'WHS Legislation Reference', bold: true, size: 56, color: NAVY })],
        alignment: AlignmentType.CENTER,
        spacing: { before: 400, after: 100 },
      }),
      new Paragraph({
        children: [new TextRun({ text: 'Model Work Health and Safety Act 2011  ·  WHS Regulations 2017', size: 22, color: '6B7280' })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 100 },
      }),
      new Paragraph({
        children: [new TextRun({ text: 'Includes duty holder obligations, penalty tiers, key section index, and regulations quick-reference.', size: 20, color: '9CA3AF', italics: true })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 600 },
      }),

      // ── 1. Overview ──
      h('1.  Legislative Framework Overview'),
      p('The Model Work Health and Safety Act 2011 (Model WHS Act) was developed by Safe Work Australia as a template for jurisdictions to adopt. It is enacted in the Commonwealth, ACT, NSW, NT, QLD, SA, TAS, and WA (with some jurisdictional variations). Victoria and Western Australia each maintain separate legislation (OHS Act 2004 and WHS Act 2020 respectively) with broadly similar obligations.'),
      p('The WHS Regulations 2017 sit under the Model WHS Act and prescribe detailed requirements for specific hazard classes, licensing, notification, and administrative processes.'),
      spacer(),

      // ── 2. Meaning of "Reasonably Practicable" ──
      h('2.  Meaning of "Reasonably Practicable" (ss 18, 30–31)'),
      p('A duty holder must do what is reasonably practicable to ensure health and safety. In deciding what is reasonably practicable, regard must be had to:'),
      bullet('The likelihood that the hazard or risk will occur'),
      bullet('The degree of harm that might result'),
      bullet('What the duty holder knows, or ought reasonably to know, about the hazard/risk and ways of eliminating/minimising it'),
      bullet('The availability and suitability of ways to eliminate or minimise the risk'),
      bullet('After assessing the above — the cost of eliminating/minimising, including whether it is grossly disproportionate to the risk'),
      p('A duty holder cannot use cost alone as a reason to avoid a control where the risk is high. The greater the risk, the less weight can be given to cost.'),
      spacer(),

      // ── 3. Hierarchy of Controls ──
      h('3.  Hierarchy of Controls (r 36)'),
      p('Regulation 36 requires the hierarchy below to be applied in order. Higher-order controls are preferred because they address the source of the risk rather than relying on human behaviour.'),
      spacer(),
      buildHOCTable(),
      spacer(),

      // ── 4. Duty Holders ──
      h('4.  Duty Holders and Their Obligations'),
      p('Multiple parties hold concurrent WHS duties under the Act. Duties cannot be transferred — each party remains responsible for their own obligations, though they must consult, co-operate, and co-ordinate with other duty holders where their duties overlap (s 16).'),
      spacer(),
      buildDutiesTable(),
      spacer(),

      // ── 5. Penalties ──
      h('5.  Penalty Tiers (ss 30–32, 230–244)'),
      p('Penalties are graduated across three categories based on the severity of the breach and its consequences. Body corporate penalties are set at 5× the individual penalty. Industrial manslaughter provisions exist in some jurisdictions as an additional Category 1-equivalent offence.'),
      spacer(),
      buildPenaltiesTable(),
      spacer(),
      p('Note: Penalties are expressed in penalty units. Figures above reflect values as at commencement; check current legislation for indexed amounts.'),
      spacer(),

      // ── 6. Notifiable Incidents ──
      h('6.  Notifiable Incidents (ss 117–122)'),
      p('A PCBU must immediately notify the regulator of a notifiable incident. A notifiable incident is:'),
      bullet('The death of a person'),
      bullet('A serious injury or illness (e.g. hospitalisation for immediate treatment, amputation, serious head/eye injury, serious burns, spinal injury, loss of bodily function, serious laceration requiring immediate in-patient treatment)'),
      bullet('A dangerous incident that exposed a person to serious risk — even if no injury occurred (e.g. uncontrolled escape of a substance, collapse of a structure, explosion, implosion, flood, or fall of any plant)'),
      spacer(),
      p('The site of a notifiable incident must be preserved until an inspector arrives or directs otherwise (s 39). Records of notifiable incidents must be kept for at least 5 years (s 122).'),
      spacer(),

      // ── 7. Act Section Index ──
      h('7.  Model WHS Act — Key Section Quick-Reference'),
      buildActTable(),
      spacer(),

      // ── 8. Regulations Quick-Reference ──
      h('8.  WHS Regulations 2017 — Key Parts Quick-Reference'),
      p('The WHS Regulations 2017 contain over 700 regulations across 14 parts. The table below summarises the parts most relevant to workplace risk management.'),
      spacer(),
      buildRegsTable(),
      spacer(),

      // ── Disclaimer ──
      new Paragraph({
        children: [new TextRun({
          text: 'Disclaimer: This document is a reference summary only and does not constitute legal advice. Always refer to the current enacted legislation in your jurisdiction. Penalty amounts and section numbers may vary between jurisdictions.',
          size: 16, italics: true, color: '9CA3AF',
        })],
        spacing: { before: 400, after: 100 },
      }),
      new Paragraph({
        children: [new TextRun({ text: `Generated: ${new Date().toLocaleDateString('en-AU', { dateStyle: 'long' })}`, size: 16, color: '9CA3AF' })],
        alignment: AlignmentType.RIGHT,
      }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('WHS_Legislation_Reference.docx', buffer);
  console.log('✅  WHS_Legislation_Reference.docx written successfully.');
}).catch(err => {
  console.error('❌  Error generating document:', err.message);
  process.exit(1);
});
