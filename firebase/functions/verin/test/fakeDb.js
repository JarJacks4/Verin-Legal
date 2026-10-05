// Minimal in-memory Firestore for exercising Cloud Function glue in tests:
// collection/doc refs, subcollections, get/set(merge)/update/delete, where('==')
// queries (refs compared by path), batches.
class Ref {
  constructor(db, path) {
    this.db = db;
    this.path = path;
    this.id = path.split('/').pop();
  }
  collection(name) {
    return new Col(this.db, `${this.path}/${name}`);
  }
  async get() {
    const d = this.db.data.get(this.path);
    return snap(this, d);
  }
  async set(v, opts = {}) {
    const cur = this.db.data.get(this.path);
    this.db.data.set(this.path, opts.merge && cur ? { ...cur, ...clean(v) } : clean(v));
  }
  async update(v) {
    const cur = this.db.data.get(this.path);
    if (!cur) throw new Error(`no document ${this.path}`);
    this.db.data.set(this.path, { ...cur, ...clean(v) });
  }
  async delete() {
    this.db.data.delete(this.path);
  }
}
function clean(v) {
  const out = {};
  for (const [k, x] of Object.entries(v)) {
    if (x === undefined) throw new Error(`undefined value for ${k}`);
    out[k] = x && x._sentinel ? new Date() : x;
  }
  return out;
}
function snap(ref, d) {
  return { id: ref.id, ref, exists: !!d, data: () => (d ? { ...d } : undefined), get: (k) => (d ? d[k] : undefined) };
}
const same = (a, b) => (a && a.path && b && b.path ? a.path === b.path : a === b);
class Col {
  constructor(db, path, filters = []) {
    this.db = db;
    this.path = path;
    this.filters = filters;
  }
  doc(id) {
    return new Ref(this.db, `${this.path}/${id || Math.random().toString(36).slice(2, 12)}`);
  }
  where(f, op, v) {
    if (op !== '==') throw new Error('fake supports == only');
    return new Col(this.db, this.path, [...this.filters, [f, v]]);
  }
  limit() {
    return this;
  }
  async get() {
    const depth = this.path.split('/').length + 1;
    const docs = [];
    for (const [p, d] of this.db.data) {
      if (!p.startsWith(`${this.path}/`) || p.split('/').length !== depth) continue;
      if (this.filters.every(([f, v]) => same(d[f], v))) docs.push(snap(new Ref(this.db, p), d));
    }
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}
class FakeDb {
  constructor() {
    this.data = new Map();
  }
  collection(name) {
    return new Col(this, name);
  }
  doc(path) {
    return new Ref(this, path);
  }
  batch() {
    const ops = [];
    return {
      set: (r, v, o) => ops.push(() => r.set(v, o)),
      update: (r, v) => ops.push(() => r.update(v)),
      delete: (r) => ops.push(() => r.delete()),
      commit: async () => {
        for (const op of ops) await op();
      },
    };
  }
}
module.exports = { FakeDb };
