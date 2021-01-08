const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp()
const bucket = admin.storage().bucket()

const supportedLanguages = ['cs-CZ', 'nl-NL', 'en-US', 'et-EE', 'fi-FI', 'de-DE', 'he-IL', 'hi-IN', 'hu-HU',
    'is-IS', 'id-ID', 'it-IT', 'ja-JP', 'ko-KR', 'fa-IR', 'pl-PL', 'pl-PT', 'ro-RO', 'ru-RU', 'sk-SK', 'es-ES',
    'sv-SE', 'tr-TR', 'uk-UA', 'vi-VN'] // languages in the checkbox


/**
 * @param {string} uid is the user id as set by firestore
 * @param {string} docid is the document id of the draft to be published
 * @param {number} numpic is the number of the picture
 * @returns the file path of the image of the published path */
function imagePathPath(uid, docid, numpic) {
    let filenamesuffix = `${docid}.${numpic}.jpg` // e.g. '.1.' symbols first picture of this doc
    return `media/paths/${uid}/${filenamesuffix}`
}

/**
 * @param {string} uid is the user id as set by firestore
 * @param {string} docid is the document id of the draft to be published
 * @param {number} numpic is the number of the picture
 * @returns the file path of the image of the draft path */
function imageDraftPath(uid, docid, numpic) {
    let filenamesuffix = `${docid}.${numpic}.jpg` // e.g. '.1.' symbols first picture of this doc
    return `media/drafts/${uid}/${filenamesuffix}`
}

/** does some common validation checks
* @param obj is the object which has the attribute
* @param {string} attr is the attribute
* @returns {boolean} */
function _isEmptyOrWrongType(obj, attr) {
    return obj[attr] === undefined || obj[attr] === null || obj[attr] === "" || typeof obj[attr] !== 'string'
}

/** @returns {Promise} Promise that rejects if validations fails. If all checks pass, the promise resolves
 * with the path  
 * @param {*} path
 * NOTE: image validation is shallow, i.e. it only checks whether url is set and points to firebase storage*/
function validate(path) {
    return new Promise((resolve, reject) => {
        // input validation
        // title
        if (_isEmptyOrWrongType(path, 'title') || path.title.length > 80) reject(new Error("Title mustn't be empty or too long"))

        // price
        if (path.price === undefined || path.price !== "") reject(new Error("Price mustn't be empty or nonzero"))

        // language
        if (path.language === undefined || !supportedLanguages.includes(path.language)) reject(new Error("Chosen language not supported"))

        // intro
        if (_isEmptyOrWrongType(path, 'intro') || path.intro.length > 1000) reject(new Error("Intro is too long or too short"))

        // chapters
        if (path.chapters === undefined || path.chapters === null) reject(new Error("Chapters mustn't be empty"))
        for (chapter of path.chapters) {
            // chapter title
            if (_isEmptyOrWrongType(chapter, 'cTitle') || chapter.cTitle.length > 80) reject(new Error("Chapter titles mustn't be empty or too long"))
            // chapter text
            if (_isEmptyOrWrongType(chapter, 'cContent') || chapter.cContent.length > 4000) reject(new Error("Chapter content mustn't be empty or too long"))

            // notifications
            if (chapter.cNotifications === undefined || chapter.cNotifications === null || chapter.cNotifications.length < 2) reject(new Error("Each chapter must have at least two notifications"))

            for (notif of chapter.cNotifications) {
                // notification title
                if (_isEmptyOrWrongType(notif, 'nTitle') || notif.nTitle.length > 65) reject(new Error("Notification titles must be 1-65 characters long"))
                // notification body
                if (_isEmptyOrWrongType(notif, 'nBody') || notif.nBody.length > 300) reject(new Error("Notification bodies must be 1-300 characters long"))
                // notification times
                if (notif.nTimePref.bedtime === undefined || notif.bedtime === null) reject(new Error("Each notification must be shown at at least one time span"))
                if (notif.nTimePref.morning === undefined || notif.morning === null) reject(new Error("Each notification must be shown at at least one time span"))
                if (notif.nTimePref.noon === undefined || notif.noon === null) reject(new Error("Each notification must be shown at at least one time span"))
                let showUpTimes = notif.nTimePref.bedtime + notif.nTimePref.morning + notif.nTimePref.noon // in js: true + true = 2, false + true = 1
                if (showUpTimes === 0) reject(new Error("Each notification must be shown at at least one time span"))
            }
        }

        // image
        if (_isEmptyOrWrongType(path, 'image')) reject(new Error('Image validation failed'))
        try {
            const hostname = new URL(path.image).hostname
            if (hostname !== 'firebasestorage.googleapis.com') reject(new Error('Image validation failed'))
        } catch (err) {
            reject(new Error('Image validation failed'))
        }

        resolve(path)
    })
}

/** moving := copying to new location and removing of old file.
 * @param {string} uid is the user id
 * @param {string} draftId is the document id of the draft to be published
 * @returns {Promise} the promise returned from google cloud storage's file move method */
function moveImagePromise(uid, draftId) {
    const imageRef = bucket.file(imageDraftPath(uid, draftId, 1))
    return imageRef.move(imagePathPath(uid, draftId, 1))
        .then(response => response[0].makePublic())
}

/** moving := copying to new location and removing of old document.
 * @pre make sure path is validated!
 * @param path is the path to be published
 * @param uid is the user id
 * @param draftId is the document id of the draft to be published
 * @returns {Promise} the promise of the deletion of the draft document, which is resolved
 * only when copying worked */
function movePathPromise(path, uid, draftId) {
    return admin.firestore()
        .collection('users').doc(uid).get()
        .then(docSnapshot => admin.firestore() // copy to new location
            .collection('users').doc(uid).collection('paths').doc(draftId)
            .set({
                ...path,
                image: 'https://storage.googleapis.com/selfhelper-8517a.appspot.com/' + imagePathPath(uid, draftId, 1),
                user: docSnapshot.get('username') || 'anonymous',
                uid: uid,
                ...((path.publishedOn === undefined)
                ? {publishedOn: admin.firestore.FieldValue.serverTimestamp()}
                : {publishedOn: path.publishedOn /* don't update the publishedOn field*/}),
            })
        )
        .then(admin.firestore().collection('users').doc(uid).collection('drafts').doc(draftId).delete())
}

/** checks whether cover image of the draft exists
 * @param path is the path to be published
 * @param uid is the user id
 * @param draftId is the document id of the draft to be published
 * @returns {Promise} promise of the path (if resolving) or an error */
function imageExists(path, uid, draftId) {
    const file = bucket.file(imageDraftPath(uid, draftId, 1))
    return file.exists()
        .then(() => path)
        .catch(err => {
            const mess = err.message
            throw new Error('Image validation failed')
        })
}

/** exposes a function so the web, so firebase clients
 * can interact with it. Validates and publishes sent path, or throws error.
 * NOTE: creation triggers the deletion of the draft and the draft image
 * @param draftId is the document id of the draft to be published
 * @returns {Promise} promise of the path (if resolving) or an error */
exports.publish = functions.region('europe-west3').https.onCall((draftId, context) => {
    /* 
    1. reupload image (necessary to forbid change after publishing)
    2. copy draft over to path location (add uid ownership attribute in user AND in path) => maybe still inside user??
       no need to have all paths in one big list as this is already done with snippet
    3. delete draft + image
    4. trigger snippet generation
    */

    // Checking that the user is authenticated.
    if (!context.auth) throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while caller is authenticated.')

    if (draftId === undefined || draftId === '' || draftId === null || typeof draftId !== 'string')
        throw new functions.https.HttpsError('failed-precondition', 'args mustn\t be empty')

    const uid = context.auth.uid

    return admin.firestore().collection('users').doc(uid).collection('drafts').doc(draftId).get() // get draft
        .then(docSnapshot => docSnapshot.data())
        .then(path => validate(path))
        .then(path => imageExists(path, uid, draftId))
        // we can't update in parallel because firestore is faster and the front-end cannot load the
        // new image url until image was moved
        .then(validatedPath => {
            // move image
            return new Promise((resolve, reject) => {
                moveImagePromise(uid, draftId)
                    .then(res => resolve(validatedPath))
                    .catch(err => {
                        err.message
                        reject(new Error('image moving failed'))
                    })
            })
        })
        .then(validatedPath => movePathPromise(validatedPath, uid, draftId))
        .then(values => 'ok')
        .catch(err => {
            if (err.code !== undefined) throw err // .code is only defined in HttpsError
            // below covers all other errors
            throw new functions.https.HttpsError('permission-denied', 'There was an error. Please try again or contact support.')
        })
})

/** deletes path of user
 * @param {String} pathid is the document id of the path
 */
exports.deletePath = functions.region('europe-west3').https.onCall((pathid, context) => {
    // Checking that the user is authenticated.
    if (!context.auth) throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while caller is authenticated.')

    if (pathid === undefined || pathid === '' || pathid === null || typeof pathid !== 'string')
        throw new functions.https.HttpsError('failed-precondition', 'args mustn\t be empty')

    const uid = context.auth.uid
    const pathpath = admin.firestore().collection('users').doc(uid).collection('paths').doc(pathid)
    const imageRef = bucket.file(imagePathPath(uid, pathid, 1))

    return Promise.all([pathpath.delete(), imageRef.delete()])
        .then(resp => 'ok')
        .catch(err => {
            err.message
            throw new functions.https.HttpsError('unknown', 'deletion encountered an error of unknown cause')
        })
})

/**
 * generates the snippet object by slicing some chapters and notifications
 * @param {Path} path is the full path
 * @param {String} uid is the user id, that is the creator of the path
 */
function generateSnippet(path, uid) {
    /**
     * take three random elements from a list. if the list is <= 3 elements big, just return the
     * the array
     * @param {Array<*>} array is the array to draw from 
     */
    const drawThreeRandomly = (array) => {
        if (array.length < 4) return array

        let threeRandomIndices = []
        while (threeRandomIndices.length < 4) {
            let randIndex = Math.floor(Math.random() * array.length)

            if (!threeRandomIndices.includes(randIndex)) {
                threeRandomIndices.push(randIndex)
            }
        }
        return [array[threeRandomIndices[0]], array[threeRandomIndices[1]], array[threeRandomIndices[2]]]
    }

    return (
        {
            id: path.id,
            likes: 0,
            dislikes: 0,
            title: path.title,
            uid: uid,
            price: path.price,
            language: path.language,
            image: path.image,
            intro: path.intro,
            publishedOn: path.publishedOn,
            timestamp: path.timestamp,
            user: path.user,
            chapters: path.chapters.slice(0, 3).map(
                (chapter, index, array) => {
                    return (
                        {
                            cTitle: chapter.cTitle,
                            cContent: chapter.cContent,
                            cNotifications: drawThreeRandomly(chapter.cNotifications)
                        }
                    )
                }
            )
        }
    )
}

/**
 * triggered by update, creation or deletion of a path. Modifies the respective snippet accordingly.
 */
exports.manageSnippet = functions.region('europe-west3')
    .firestore
    .document('users/{userid}/paths/{pathid}')
    .onWrite((change, context) => {
        const pid = context.params.pathid
        const uid = context.params.userid
        const fullPath = change.after.data() // path is the data, not the directory
        const snippetPath = admin.firestore().collection('snippets').doc(pid)

        // if deletion, delete snippet if exists
        if (!change.after.exists) return snippetPath.delete()

        // else update or set snippet
        return snippetPath.set(generateSnippet(fullPath, uid))
    })


/** used by signed in user to like a snippet. The like is saved in a counter in
 * the snippet document and the user document.
 * @param String docIdSnippet is the firebase document id of the snippet.
 */
exports.like = functions.region('europe-west3').https.onCall((docIdSnippet, context) => {
    if (!context.auth) throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while caller is authenticated.')

    if (docIdSnippet === undefined || docIdSnippet === '' || docIdSnippet === null || typeof docIdSnippet !== 'string')
        throw new functions.https.HttpsError('failed-precondition', 'args mustn\t be empty')

    const uid = context.auth.uid
    const db = admin.firestore()

    // had already liked path check
    const userLikedPathsQuery = db.collection('users')
            .where('likes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)

    // had disliked path check
    const userDislikedPathsQuery = db.collection('users')
            .where('dislikes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)
    
    // hadn't (dis)liked path before
    const snippetPathRef = db.collection('snippets').doc(docIdSnippet)

    return Promise.all([userLikedPathsQuery.get(), userDislikedPathsQuery.get(), snippetPathRef.get()])
    .then(results => {
        const hadLikedBefore = !results[0].empty
        const hadDislikedBefore = !results[1].empty
        const documentExists = results[2].exists

        if (!documentExists) throw new functions.https.HttpsError('failed-precondition', "Path doesn't exist")
        if (hadLikedBefore) throw new functions.https.HttpsError('already-exists', 'Path was already liked before')
        if (hadDislikedBefore) return {'hadDislikedBefore' : true}
        return {'hadDislikedBefore' : false}
    })
    .then(obj => {
        const increment = admin.firestore.FieldValue.increment(1)
        const decrement = admin.firestore.FieldValue.increment(-1)
        const userRef = db.collection('users').doc(uid)
        
        const batch = db.batch()

        if (obj.hadDislikedBefore) {
            batch.set(userRef, {
                'dislikes': admin.firestore.FieldValue.arrayRemove(docIdSnippet),
                'likes' : admin.firestore.FieldValue.arrayUnion(docIdSnippet)
            }, {merge: true})
            batch.set(snippetPathRef, {'likes' : increment, 'dislikes' : decrement}, {merge: true})
        } else {
            batch.set(userRef, {'likes': admin.firestore.FieldValue.arrayUnion(docIdSnippet)}, {merge: true})
            batch.set(snippetPathRef, {'likes' : increment}, {merge: true})
        }
        return batch.commit()
    })

})

/** used by signed in user to dislike a snippet. The dislike is saved in a counter in
 * the snippet document and the user document.
 * @param String docIdSnippet is the firebase document id of the snippet.
 */
exports.dislike = functions.region('europe-west3').https.onCall((docIdSnippet, context) => {
    if (!context.auth) throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while caller is authenticated.')

    if (docIdSnippet === undefined || docIdSnippet === '' || docIdSnippet === null || typeof docIdSnippet !== 'string')
        throw new functions.https.HttpsError('failed-precondition', 'args mustn\t be empty')

    const uid = context.auth.uid
    const db = admin.firestore()

    // had already liked path check
    const userLikedPathsQuery = db.collection('users')
            .where('likes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)

    // had disliked path check
    const userDislikedPathsQuery = db.collection('users')
            .where('dislikes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)
    
    // hadn't (dis)liked path before
    const snippetPathRef = db.collection('snippets').doc(docIdSnippet)

    return Promise.all([userLikedPathsQuery.get(), userDislikedPathsQuery.get(), snippetPathRef.get()])
    .then(results => {
        const hadLikedBefore = !results[0].empty
        const hadDislikedBefore = !results[1].empty
        const documentExists = results[2].exists

        if (!documentExists) throw new functions.https.HttpsError('failed-precondition', "Path doesn't exist")
        if (hadDislikedBefore) throw new functions.https.HttpsError('already-exists', 'Path was already disliked before')
        if (hadLikedBefore) return {'hadLikedBefore' : true}
        return {'hadLikedBefore' : false}
    })
    .then(obj => {
        const increment = admin.firestore.FieldValue.increment(1)
        const decrement = admin.firestore.FieldValue.increment(-1)
        const userRef = db.collection('users').doc(uid)
        
        const batch = db.batch()

        if (obj.hadLikedBefore) {
            batch.set(userRef, {
                'likes': admin.firestore.FieldValue.arrayRemove(docIdSnippet),
                'dislikes' : admin.firestore.FieldValue.arrayUnion(docIdSnippet)
            }, {merge: true})
            batch.set(snippetPathRef, {'dislikes' : increment, 'likes' : decrement}, {merge: true})
        } else {
            batch.set(userRef, {'dislikes': admin.firestore.FieldValue.arrayUnion(docIdSnippet)}, {merge: true})
            batch.set(snippetPathRef, {'dislikes' : increment}, {merge: true})
        }
        return batch.commit()
    })

})

/** used by signed in user to unlike a snippet, or _undislike_ a snippet.
 * @param String docIdSnippet is the firebase document id of the snippet.
 */
exports.unlike = functions.region('europe-west3').https.onCall((docIdSnippet, context) => {
    if (!context.auth) throw new functions.https.HttpsError('failed-precondition', 'The function must be called ' +
        'while caller is authenticated.')

    if (docIdSnippet === undefined || docIdSnippet === '' || docIdSnippet === null || typeof docIdSnippet !== 'string')
        throw new functions.https.HttpsError('failed-precondition', 'args mustn\t be empty')

    const uid = context.auth.uid
    const db = admin.firestore()

    // had already liked path check
    const userLikedPathsQuery = db.collection('users')
            .where('likes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)

    // had disliked path check
    const userDislikedPathsQuery = db.collection('users')
            .where('dislikes', 'array-contains', docIdSnippet)
            .where(admin.firestore.FieldPath.documentId(), '==', uid)
    
    // hadn't (dis)liked path before
    const snippetPathRef = db.collection('snippets').doc(docIdSnippet)

    return Promise.all([userLikedPathsQuery.get(), userDislikedPathsQuery.get(), snippetPathRef.get()])
    .then(results => {
        const hadLikedBefore = !results[0].empty
        const hadDislikedBefore = !results[1].empty
        const documentExists = results[2].exists

        if (!documentExists) throw new functions.https.HttpsError('failed-precondition', "Path doesn't exist")
        if (!hadDislikedBefore && !hadLikedBefore) throw new functions.https.HttpsError('failed-precondition', "Path wasn't liked or disliked before")
        return {
            hadLikedBefore : (hadLikedBefore) ? true : false
        }
    })
    .then(obj => {
        const decrement = admin.firestore.FieldValue.increment(-1)
        const userRef = db.collection('users').doc(uid)
        
        const batch = db.batch()

        if (obj.hadLikedBefore) {
            batch.set(userRef, {
                'likes': admin.firestore.FieldValue.arrayRemove(docIdSnippet),
            }, {merge: true})
            batch.set(snippetPathRef, {'likes' : decrement}, {merge: true})
        } else {
            batch.set(userRef, {
                'dislikes': admin.firestore.FieldValue.arrayRemove(docIdSnippet),
            }, {merge: true})
            batch.set(snippetPathRef, {'dislikes' : decrement}, {merge: true})
        }
        return batch.commit()
    })

})