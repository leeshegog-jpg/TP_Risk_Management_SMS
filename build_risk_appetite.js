'use strict';
/**
 * build_risk_appetite.js
 * Generates Risk_Appetite_Framework.docx — a 5×5 risk matrix with
 * appetite-level table tied to SFARP thresholds.
 *
 * Usage:  node build_risk_appetite.js
 * Output: Risk_Appetite_Framework.docx
 */

const {
  Document, Packer, Paragraph, Table, TableRow, TableCell,
  TextRun, HeadingLevel, AlignmentType, WidthType, ShadingType,
  TableLayoutType, BorderStyle, VerticalAlign,
} = require('docx');
const fs = require('fs');

// ── Colour map ────────────────────────────────────────────────────────────────
function riskMeta(score) {
  if (score >= 17) return { fill: 'C00000', rating: 'EXTREME',  sfarp: 'Broadly Unacceptable' };
  if (score >= 10) return { fill: 'FF7C00', rating: 'HIGH',     sfarp: 'Intolerable (ALARP)'  };
  if (score >= 5)  return { fill: 'FFC000', rating: 'MEDIUM',   sfarp: 'Tolerable (ALARP)'    };
  return             { fill: '70AD47', rating: 'LOW',      sfarp: 'Broadly Acceptable'   };
}

// ── Shared border (thin, grey) ────────────────────────────────────────────────
const BORDER = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };

// ── Helpers ───────────────────────────────────────────────────────────────────
function hCell(text, shade = '1F3864') {
  return new TableCell({
    shading: { fill: shade, type: ShadingType.CLEAR, color: 'auto' },
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text, bold: true, color: 'FFFFFF', size: 20 })],
    })],
  });
}

function matrixCell(score) {
  const { fill, rating } = riskMeta(score);
  return new TableCell({
    shading: { fill, type: ShadingType.CLEAR, color: 'auto' },
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: String(score), bold: true, color: 'FFFFFF', size: 24 })],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: rating, color: 'FFFFFF', size: 14 })],
      }),
    ],
  });
}

function rowHeaderCell(label, sub) {
  return new TableCell({
    shading: { fill: '1F3864', type: ShadingType.CLEAR, color: 'auto' },
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: label, bold: true, color: 'FFFFFF', size: 20 })],
      }),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: sub, color: 'FFFFFF', size: 14 })],
      }),
    ],
  });
}

function dataCell(text, bold = false, shade = null, textColor = '1F2937') {
  const cell = new TableCell({
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.LEFT,
      children: [new TextRun({ text, bold, color: textColor, size: 18 })],
    })],
  });
  if (shade) cell.options = { ...cell.options, shading: { fill: shade, type: ShadingType.CLEAR, color: 'auto' } };
  return cell;
}

function appetiteCell(text, bold = false, fill = null, textColor = '1F2937') {
  return new TableCell({
    shading: fill ? { fill, type: ShadingType.CLEAR, color: 'auto' } : undefined,
    borders: BORDERS,
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text, bold, color: fill ? 'FFFFFF' : textColor, size: 18 })],
    })],
  });
}

// ── Risk matrix data ─────────────────────────────────────────────────────────
//   Rows: likelihood  (Almost Certain=5 … Rare=1, top→bottom)
//   Cols: consequence (Negligible=1 … Catastrophic=5, left→right)
const LIKELIHOODS = [
  { label: 'Almost Certain', sub: '5' },
  { label: 'Likely',         sub: '4' },
  { label: 'Possible',       sub: '3' },
  { label: 'Unlikely',       sub: '2' },
  { label: 'Rare',           sub: '1' },
];
const CONSEQUENCES = [
  { label: 'Negligible',   val: 1 },
  { label: 'Minor',        val: 2 },
  { label: 'Moderate',     val: 3 },
  { label: 'Major',        val: 4 },
  { label: 'Catastrophic', val: 5 },
];

function buildMatrix() {
  const headerRow = new TableRow({
    tableHeader: true,
    children: [
      hCell('Likelihood →\nConsequence ↓', '374151'),
      ...CONSEQUENCES.map(c => hCell(`${c.label}\n(${c.val})`)),
    ],
  });

  const dataRows = LIKELIHOODS.map((l, idx) => {
    const lVal = 5 - idx;
    return new TableRow({
      children: [
        rowHeaderCell(l.label, `(${lVal})`),
        ...CONSEQUENCES.map(c => matrixCell(lVal * c.val)),
      ],
    });
  });

  return new Table({
    layout: TableLayoutType.FIXED,
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [headerRow, ...dataRows],
  });
}

// ── Appetite table ────────────────────────────────────────────────────────────
const APPETITE_ROWS = [
  { level: 'LOW',     scores: '1 – 4',   fill: '70AD47', sfarp: 'Broadly Acceptable',    action: 'Maintain current controls; review annually. No further risk reduction required.' },
  { level: 'MEDIUM',  scores: '5 – 9',   fill: 'FFC000', sfarp: 'Tolerable (ALARP)',      action: 'Reduce risk if reasonably practicable. Document cost-benefit rationale. Review within 90 days.' },
  { level: 'HIGH',    scores: '10 – 16', fill: 'FF7C00', sfarp: 'Intolerable (ALARP)',    action: 'Must reduce risk before proceeding. Additional controls mandatory. Senior management sign-off required.' },
  { level: 'EXTREME', scores: '17 – 25', fill: 'C00000', sfarp: 'Broadly Unacceptable',  action: 'Stop work immediately. Do not proceed until risk is reduced to at least HIGH or below.' },
];

function buildAppetiteTable() {
  const headerRow = new TableRow({
    tableHeader: true,
    children: [
      hCell('Rating'),
      hCell('Score Range'),
      hCell('SFARP Status'),
      hCell('Required Action'),
    ],
  });

  const dataRows = APPETITE_ROWS.map(r => new TableRow({
    children: [
      appetiteCell(r.level,   true, r.fill),
      appetiteCell(r.scores,  false, r.fill),
      appetiteCell(r.sfarp,   false, null, '1F2937'),
      new TableCell({
        borders: BORDERS,
        verticalAlign: VerticalAlign.CENTER,
        children: [new Paragraph({
          children: [new TextRun({ text: r.action, size: 18 })],
        })],
      }),
    ],
  }));

  return new Table({
    layout: TableLayoutType.FIXED,
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [headerRow, ...dataRows],
  });
}

// ── Legend ────────────────────────────────────────────────────────────────────
function legendRow(fill, rating, range) {
  return new TableRow({
    children: [
      new TableCell({
        shading: { fill, type: ShadingType.CLEAR, color: 'auto' },
        borders: BORDERS,
        width: { size: 20, type: WidthType.PERCENTAGE },
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: rating, bold: true, color: 'FFFFFF', size: 18 })],
        })],
      }),
      new TableCell({
        borders: BORDERS,
        width: { size: 80, type: WidthType.PERCENTAGE },
        children: [new Paragraph({
          children: [new TextRun({ text: range, size: 18 })],
        })],
      }),
    ],
  });
}

// ── Document assembly ─────────────────────────────────────────────────────────
function h(text, level = HeadingLevel.HEADING_1) {
  return new Paragraph({ text, heading: level, spacing: { before: 300, after: 120 } });
}

function p(text) {
  return new Paragraph({ children: [new TextRun({ text, size: 20 })], spacing: { after: 120 } });
}

function spacer() {
  return new Paragraph({ text: '', spacing: { after: 200 } });
}

const doc = new Document({
  creator: 'Control Effectiveness Calculator',
  title:   'Risk Appetite Framework',
  description: 'SFARP-aligned 5×5 risk matrix and appetite-level reference',
  styles: {
    default: {
      document: {
        run: { font: 'Calibri', size: 20 },
      },
    },
  },
  sections: [{
    properties: { page: { margin: { top: 720, bottom: 720, left: 1080, right: 1080 } } },
    children: [
      // ── Title ──
      new Paragraph({
        children: [new TextRun({ text: 'Risk Appetite Framework', bold: true, size: 52, color: '1F3864' })],
        alignment: AlignmentType.CENTER,
        spacing: { before: 400, after: 100 },
      }),
      new Paragraph({
        children: [new TextRun({ text: 'SFARP-Aligned 5×5 Risk Matrix and Appetite Reference', size: 24, color: '6B7280' })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 600 },
      }),

      // ── Section 1: Matrix ──
      h('1.  Risk Rating Matrix'),
      p('Score = Likelihood rating × Consequence rating. Identify the cell at the intersection of the event\'s likelihood and its worst credible consequence.'),
      spacer(),
      buildMatrix(),
      spacer(),

      // ── Legend ──
      h('2.  Colour Legend', HeadingLevel.HEADING_2),
      new Table({
        layout: TableLayoutType.FIXED,
        width: { size: 60, type: WidthType.PERCENTAGE },
        rows: [
          legendRow('70AD47', 'LOW',     'Score 1 – 4'),
          legendRow('FFC000', 'MEDIUM',  'Score 5 – 9'),
          legendRow('FF7C00', 'HIGH',    'Score 10 – 16'),
          legendRow('C00000', 'EXTREME', 'Score 17 – 25'),
        ],
      }),
      spacer(),

      // ── Section 2: Appetite ──
      h('3.  Organisational Risk Appetite and SFARP Thresholds'),
      p('The table below maps each risk rating to the organisation\'s risk appetite and the corresponding SFARP decision requirement.'),
      spacer(),
      buildAppetiteTable(),
      spacer(),

      // ── Section 3: Guidance ──
      h('4.  Guidance Notes'),
      p('SFARP (So Far As Reasonably Practicable) is the standard of care required under the Model Work Health and Safety Act 2011. A risk that is Broadly Acceptable requires no further control investment. A risk in the ALARP region must be reduced unless the cost of further reduction is grossly disproportionate to the benefit. A risk that is Broadly Unacceptable must not be tolerated — work must stop and controls strengthened before resumption.'),
      spacer(),
      p('This matrix must be reviewed at least annually or whenever a significant change to a hazard, process or control occurs. All assessments that produce a HIGH or EXTREME rating require documented senior management review.'),
      spacer(),

      new Paragraph({
        children: [new TextRun({ text: `Generated: ${new Date().toLocaleDateString('en-AU', { dateStyle: 'long' })}`, size: 16, color: '9CA3AF' })],
        alignment: AlignmentType.RIGHT,
        spacing: { before: 400 },
      }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('Risk_Appetite_Framework.docx', buffer);
  console.log('✅  Risk_Appetite_Framework.docx written successfully.');
}).catch(err => {
  console.error('❌  Error generating document:', err.message);
  process.exit(1);
});
