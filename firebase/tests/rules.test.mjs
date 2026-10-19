// Checks firebase/firestore.rules against the local emulator. Run from this
// folder with `npm install && npm test` (needs Java for the emulator).

import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, getDocs, collection, deleteDoc } from 'firebase/firestore';
import fs from 'fs';

const env = await initializeTestEnvironment({
  projectId: 'demo-iadaptops',
  firestore: { rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
});
await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  await setDoc(doc(db, 'invites/anacatarinasveiga@gmail.com'), { programID: 'anaChallenge', name: 'Ana Catarina Veiga' });
  await setDoc(doc(db, 'users/other'), { name: 'Other', startDate: 1 });
  await setDoc(doc(db, 'users/other/sessions/s1'), { dayIndex: 1, date: 1 });
});

const admin = env.authenticatedContext('vidi', { email: 'ividi.dev@gmail.com', email_verified: true }).firestore();
const fakeAdmin = env.authenticatedContext('evil', { email: 'ividi.dev@gmail.com', email_verified: false }).firestore();
const oldAdmin = env.authenticatedContext('david', { email: 'damartins89@gmail.com', email_verified: true }).firestore();
const ana = env.authenticatedContext('ana', { email: 'AnaCatarinaSVeiga@gmail.com', email_verified: true }).firestore();
const bob = env.authenticatedContext('bob', { email: 'bob@mail.pt', email_verified: true }).firestore();
const anon = env.unauthenticatedContext().firestore();

let ok = 0, bad = 0;
async function check(name, p) { try { await p; ok++; console.log('ok  ', name); } catch (e) { bad++; console.log('FAIL', name, e.message.split('\n')[0]); } }

// Owners
await check('bob creates own profile without program', assertSucceeds(setDoc(doc(bob, 'users/bob'), { name: 'Bob', startDate: 1 })));
await check('bob cannot give himself Ana program', assertFails(setDoc(doc(bob, 'users/bob'), { programID: 'anaChallenge' }, { merge: true })));
await check('bob reads own', assertSucceeds(getDoc(doc(bob, 'users/bob'))));
await check('bob cannot read other', assertFails(getDoc(doc(bob, 'users/other'))));
await check('bob cannot read other sessions', assertFails(getDocs(collection(bob, 'users/other/sessions'))));
await check('bob cannot list users', assertFails(getDocs(collection(bob, 'users'))));
await check('bob cannot read invites', assertFails(getDocs(collection(bob, 'invites'))));
await check('bob cannot write invite', assertFails(setDoc(doc(bob, 'invites/bob@mail.pt'), { programID: 'anaChallenge' })));
await check('bob writes own session', assertSucceeds(setDoc(doc(bob, 'users/bob/sessions/x'), { dayIndex: 1, date: 2 })));
await check('bob cannot write other session', assertFails(setDoc(doc(bob, 'users/other/sessions/y'), { dayIndex: 1 })));
await check('anon cannot read', assertFails(getDoc(doc(anon, 'users/bob'))));
await check('bob cannot pretend to be another email', assertFails(setDoc(doc(bob, 'users/bob'), { email: 'ividi.dev@gmail.com' }, { merge: true })));
await check('bob cannot add unknown fields', assertFails(setDoc(doc(bob, 'users/bob'), { role: 'admin' }, { merge: true })));
await check('bob cannot log an impossible day', assertFails(setDoc(doc(bob, 'users/bob/sessions/bad'), { dayIndex: 99, date: 2 })));
await check('bob cannot store a huge note', assertFails(setDoc(doc(bob, 'users/bob/sessions/big'), { dayIndex: 2, date: 2, note: 'x'.repeat(501) })));
await check('bob logs a full check-in', assertSucceeds(setDoc(doc(bob, 'users/bob/sessions/full'), { dayIndex: 2, date: 1.5, durationSeconds: 1020, lowEnergy: true, energy: 3, discomfort: 1, note: 'ok' })));
await check('bob deletes his session', assertSucceeds(deleteDoc(doc(bob, 'users/bob/sessions/full'))));
await check('bob stores his real email', assertSucceeds(setDoc(doc(bob, 'users/bob'), { email: 'bob@mail.pt' }, { merge: true })));

// Ana and her invite (email in different case)
await check('ana reads own invite', assertSucceeds(getDoc(doc(ana, 'invites/anacatarinasveiga@gmail.com'))));
await check('ana cannot claim wrong program', assertFails(setDoc(doc(ana, 'users/ana'), { programID: 'standard', name: 'Ana' })));
await check('ana claims invited program', assertSucceeds(setDoc(doc(ana, 'users/ana'), { programID: 'anaChallenge', name: 'Ana', email: 'anacatarinasveiga@gmail.com' }, { merge: true })));
await check('ana updates her settings', assertSucceeds(setDoc(doc(ana, 'users/ana'), { startDate: 5, updatedAt: 5 }, { merge: true })));
await check('ana cannot change program afterwards', assertFails(setDoc(doc(ana, 'users/ana'), { programID: 'standard' }, { merge: true })));
await check('ana cannot read admin views', assertFails(getDocs(collection(ana, 'users'))));

// Admin
await check('admin lists users', assertSucceeds(getDocs(collection(admin, 'users'))));
await check('admin reads sessions of others', assertSucceeds(getDocs(collection(admin, 'users/other/sessions'))));
await check('admin assigns program', assertSucceeds(setDoc(doc(admin, 'users/ana'), { programID: 'standard' }, { merge: true })));
await check('admin assigns the personalized plan', assertSucceeds(setDoc(doc(admin, 'users/ana'), { programID: 'personalized' }, { merge: true })));
await check('bob saves his health answers', assertSucceeds(setDoc(doc(bob, 'users/bob/private/health'), { profile: '{"energy":3}', updatedAt: 5 })));
await check('bob reads his health answers', assertSucceeds(getDoc(doc(bob, 'users/bob/private/health'))));
await check('health answers must be small', assertFails(setDoc(doc(bob, 'users/bob/private/health'), { profile: 'x'.repeat(4001), updatedAt: 5 })));
await check('no other private documents', assertFails(setDoc(doc(bob, 'users/bob/private/other'), { profile: 'x', updatedAt: 5 })));
await check('ana cannot read bob health answers', assertFails(getDoc(doc(ana, 'users/bob/private/health'))));
await check('admin cannot read health answers', assertFails(getDoc(doc(admin, 'users/bob/private/health'))));
await check('admin cannot write health answers', assertFails(setDoc(doc(admin, 'users/bob/private/health'), { profile: '{}', updatedAt: 1 })));
await check('bob deletes his health answers', assertSucceeds(deleteDoc(doc(bob, 'users/bob/private/health'))));
await check('admin cannot assign an unknown program', assertFails(setDoc(doc(admin, 'users/ana'), { programID: 'whatever' }, { merge: true })));
await check('admin writes invite', assertSucceeds(setDoc(doc(admin, 'invites/new@mail.pt'), { programID: 'anaChallenge' })));
await check('admin deletes invite', assertSucceeds(deleteDoc(doc(admin, 'invites/new@mail.pt'))));
await check('admin cannot write others sessions', assertFails(setDoc(doc(admin, 'users/other/sessions/z'), { dayIndex: 2 })));
await check('unverified admin email is not admin', assertFails(getDocs(collection(fakeAdmin, 'users'))));
await check('previous admin email is no longer admin', assertFails(getDocs(collection(oldAdmin, 'users'))));

await env.cleanup();
console.log(`\n${ok} passed, ${bad} failed`);
process.exit(bad ? 1 : 0);
