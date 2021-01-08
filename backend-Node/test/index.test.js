const chai = require('chai').use(require('chai-as-promised')) // test suite
const should = chai.should()
const assert = chai.assert

const admin = require('firebase-admin');
const test; // removed

describe('Cloud Functions', function () {
    this.timeout(0)
    var functions
    var uid = 'test-uid'
    var docid = 'test-doc-id'
    var localImagePath = './test/testimg.jpg'
    var data = require('./publish-working.json')

    before(() => {
        functions = require('../index.js')
    })

    // one for all publish tests which should end successful
    // these actually change the database / storage, so we need
    // to revert the changes in afterEach
    describe('publish successful', () => {

        it('should publish valid path', async () => {
            // setup
            const data = require('./publish-working.json')
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).set(data),
                admin.storage().bucket().upload(localImagePath, { destination: `media/drafts/${uid}/${docid}.1.jpg` }),
            ])
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.publish)
                    let userId = uid
                    return wrapped(docid, {
                        auth: { uid: userId, },
                    })
                })
                .then(args => {
                    return Promise.all([
                        admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).get(),
                        admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).get(),
                        admin.storage().bucket().file(`media/drafts/${uid}/${docid}.1.jpg`).exists(),
                        admin.storage().bucket().file(`media/paths/${uid}/${docid}.1.jpg`).exists()
                    ])
                })
                .then(([draftSnapshot, pathSnapshot, imgdraftExistsCallback, imgPathExistsCallback]) => {
                    assert.strictEqual(draftSnapshot.exists, false)
                    assert.strictEqual(pathSnapshot.exists, true)
                    assert.strictEqual(imgdraftExistsCallback[0], false)
                    assert.strictEqual(imgPathExistsCallback[0], true)
                    return
                })
                .should.be.fulfilled
        })

        afterEach(async () => {
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).delete(),
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).delete(),
                admin.storage().bucket().file(`media/drafts/${uid}/${docid}.1.jpg`).delete(),
                admin.storage().bucket().file(`media/paths/${uid}/${docid}.1.jpg`).delete()
            ])
                .catch(err => {
                    err.message
                    return
                })
                .should.be.fulfilled
        })
    })

    // one for all publish tests which should end unsuccessful
    // these don't change the database, because they should fail before doing so
    describe('publish unsuccessful, error in path', () => {
        var invalidData

        before(() => {
            admin.storage().bucket().upload(localImagePath, { destination: `media/drafts/${uid}/${docid}.1.jpg` })
                .catch(err => console.log(err.message))
        })

        beforeEach(() => {
            invalidData = JSON.parse(JSON.stringify(data))
        })

        it('should deny because different user tries to upload', async () => {
            // setup
            return admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).set(data)
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.publish)
                    return wrapped(docid, {
                        auth: { uid: 'test-uid-other-user' },
                        authType: 'USER'
                    })
                })
                .should.be.rejected
        })

        it('should deny because no title was given', async () => {
            // setup
            delete invalidData.title
            return admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).set(invalidData)
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.publish)
                    let userId = uid
                    return wrapped(docid, {
                        auth: { uid: userId, },
                    })
                })
                .should.be.rejected
        })

        it('should deny because title was too long', async () => {
            // setup
            invalidData.title = 'THIS IS A SUPER LONG TITLE WHICH SHOULDNT WORK BECAUSE IT IS WAY TOO LONG TO BE READ BY ANYONE Y R U STILL READING THISSS'
            return admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).set(invalidData)
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.publish)
                    let userId = uid
                    return wrapped(docid, {
                        auth: { uid: userId, },
                    })
                })
                .should.be.rejected
        })

        after(() => {
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).delete(),
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).delete(),
                admin.storage().bucket().file(`media/drafts/${uid}/${docid}.1.jpg`).delete(),
                admin.storage().bucket().file(`media/paths/${uid}/${docid}.1.jpg`).delete()
            ])
                .catch(err => {
                    err.message
                    return
                })
                .should.be.fulfilled
        })

    })

    describe('publish unsuccessful, error in image', () => {
        var invalidData

        beforeEach(() => {
            invalidData = JSON.parse(JSON.stringify(data))
        })

        it('should deny because image was set in object, but not uploaded to cloud storage', async () => {
            // setup
            return admin.firestore().collection('users').doc(uid).collection('drafts').doc(docid).set(invalidData)
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.publish)
                    let userId = uid
                    return wrapped(docid, {
                        auth: { uid: userId, },
                    })
                })
                .should.be.rejected
        })

    })

    describe('deletion', () => {
        it('should delete published path', async () => {
            // setup
            const data = require('./publish-working.json')
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data),
                admin.storage().bucket().upload(localImagePath, { destination: `media/paths/${uid}/${docid}.1.jpg` }),
            ])
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.deletePath)
                    let userId = uid
                    return wrapped(docid, {
                        auth: { uid: userId, },
                    })
                })
                .then(args => {
                    let ref = admin.firestore().collection('users').doc(uid).collection('paths').doc(docid)
                    let fileref = admin.storage().bucket().file(`media/paths/${uid}/${docid}.1.jpg`)
                    return Promise.all([ref.get(), fileref.exists()])
                })
                .then(([docSnapshot, fileExRes]) => {
                    if (!docSnapshot.exists && fileExRes[0] === false) return 'ok'
                    throw new Error('wtf')
                })
                .should.become('ok')
        })

        it('should reject when no user is signed in', async () => {
            // setup
            const data = require('./publish-working.json')
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data),
                admin.storage().bucket().upload(localImagePath, { destination: `media/paths/${uid}/${docid}.1.jpg` }),
            ])
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.deletePath)
                    return wrapped(docid, {
                        auth: { uid: null, },
                    })
                })
                .should.be.rejected
        })

        it('should reject when no path found', async () => {
            // setup
            const data = require('./publish-working.json')
            return Promise.all([])
                .then(args => {
                    // test
                    const wrapped = test.wrap(functions.deletePath)
                    let userid = uid
                    return wrapped(docid, {
                        auth: { uid: userid, },
                    })
                })
                .should.be.rejected
        })

        afterEach(async () => {
            return Promise.all([
                admin.storage().bucket().file(`media/paths/${uid}/${docid}.1.jpg`).delete(),
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).delete()
            ])
                .catch(err => {
                    err.message
                    return 'ok'
                })
                .should.be.fulfilled
        })
    })

    describe('likes and dislikes', () => {

        it('should like when user is signed in and wasn\'t (dis)liked before', async () => {
            // setup
            const path = require('./publish-working.json')

            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set(data) // this is so we dont wait for onCreate
            // test
            const likeWrapped = test.wrap(functions.like)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.likes.includes(docid), true, '1')
                assert.strictEqual(user.dislikes === undefined, true, '2')
                assert.strictEqual(snippet.likes === 1, true, '3')
                assert.strictEqual(snippet.dislikes === undefined, true, '4')
                return
            })
                .should.be.fulfilled
        })

        it('should dislike when user is signed in and wasn\'t (dis)liked before', async () => {
            // setup
            const path = require('./publish-working.json')

            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set(data) // this is so we dont wait for onCreate
            // test
            const likeWrapped = test.wrap(functions.dislike)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.dislikes.includes(docid), true, '1')
                assert.strictEqual(user.likes === undefined, true, '2')
                assert.strictEqual(snippet.likes === undefined, true, '3')
                assert.strictEqual(snippet.dislikes === 1, true, '4')
                return
            })
                .should.be.fulfilled
        })

        it('shouldn\'t change like counts if path was already liked', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                likes: 1,
                dislikes: 0,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ likes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.like)
            return likeWrapped(docid, {
                auth: { uid: uid, },
            })
                .then(args => Promise.all([
                    admin.firestore().collection('users').doc(uid).get(),
                    admin.firestore().collection('snippets').doc(docid).get()
                ]))
                .then(([userSnapshot, snippetSnapshot]) => {
                    const user = userSnapshot.data()
                    const snippet = snippetSnapshot.data()

                    assert.strictEqual(user.likes.includes(docid), true, '1')
                    assert.strictEqual(user.likes.length === 1, true, '2')
                    assert.strictEqual(user.dislikes === undefined, true, '3')
                    assert.strictEqual(snippet.likes === 1, true, '4')
                    assert.strictEqual(snippet.dislikes === 0, true, '5')
                    return
                })
                .should.be.rejected
        })

        it('shouldn\'t change dislike counts if path was already disliked', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                likes: 3,
                dislikes: 3,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ dislikes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.dislike)
            return likeWrapped(docid, {
                auth: { uid: uid, },
            })
                .then(args => Promise.all([
                    admin.firestore().collection('users').doc(uid).get(),
                    admin.firestore().collection('snippets').doc(docid).get()
                ]))
                .then(([userSnapshot, snippetSnapshot]) => {
                    const user = userSnapshot.data()
                    const snippet = snippetSnapshot.data()

                    assert.strictEqual(user.dislikes.includes(docid), true, '1')
                    assert.strictEqual(user.dislikes.length === 1, true, '2')
                    assert.strictEqual(user.likes === undefined, true, '3')
                    assert.strictEqual(snippet.likes === 3, true, '4')
                    assert.strictEqual(snippet.dislikes === 3, true, '5')
                    return
                })
                .should.be.rejected
        })

        it('should handle like if disliked before', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                dislikes: 1,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ dislikes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.like)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.dislikes.length === 0, true, '1')
                assert.strictEqual(user.likes.length === 1, true, '2')
                assert.strictEqual(user.likes.includes(docid), true, '3')
                assert.strictEqual(snippet.likes === 1, true, '4')
                assert.strictEqual(snippet.dislikes === undefined || snippet.dislikes === 0, true, '5')
                return
            })
                .should.be.fulfilled
        })

        it('should handle dislike if liked before', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                likes: 1,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ likes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.dislike)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.likes.length === 0, true, '1')
                assert.strictEqual(user.dislikes.length === 1, true, '2')
                assert.strictEqual(user.dislikes.includes(docid), true, '3')
                assert.strictEqual(snippet.dislikes === 1, true, '4')
                assert.strictEqual(snippet.likes === undefined || snippet.likes === 0, true, '5')
                return
            })
                .should.be.fulfilled
        })

        it('should handle unlikes', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                likes: 1,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ likes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.unlike)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.likes.length === 0, true, '1')
                assert.strictEqual(snippet.likes === 0, true, '2')
                return
            })
                .should.be.fulfilled
        })

        it('should handle undislikes', async () => {
            // setup
            const path = require('./publish-working.json')
            await admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).set(data)
            await admin.firestore().collection('snippets').doc(docid).set({
                ...data,
                dislikes: 1,
            }) // this is so we dont wait for onCreate
            await admin.firestore().collection('users').doc(uid).set({ dislikes: [docid] })

            // test
            const likeWrapped = test.wrap(functions.unlike)
            await likeWrapped(docid, {
                auth: { uid: uid, },
            })

            return Promise.all([
                admin.firestore().collection('users').doc(uid).get(),
                admin.firestore().collection('snippets').doc(docid).get()
            ]).then(([userSnapshot, snippetSnapshot]) => {
                const user = userSnapshot.data()
                const snippet = snippetSnapshot.data()

                assert.strictEqual(user.dislikes.length === 0, true, '1')
                assert.strictEqual(snippet.dislikes === 0, true, '2')
                return
            })
                .should.be.fulfilled
        })

        afterEach(async () => {
            return Promise.all([
                admin.firestore().collection('users').doc(uid).collection('paths').doc(docid).delete(),
                admin.firestore().collection('snippets').doc(docid).delete(),
                admin.firestore().collection('users').doc(uid).delete(),
            ])
        })
    })


    after(() => {
        test.cleanup()
    })

})
