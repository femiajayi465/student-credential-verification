;; Credential Issuance Contract
;; Issue verified academic credentials and professional certifications

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-not-authorized-issuer (err u105))
(define-constant err-credential-revoked (err u106))

;; Credential types
(define-constant type-bachelors "bachelors")
(define-constant type-masters "masters")
(define-constant type-doctoral "doctoral")
(define-constant type-certificate "certificate")
(define-constant type-diploma "diploma")
(define-constant type-transcript "transcript")
(define-constant type-professional "professional")

;; Credential status
(define-constant status-active "active")
(define-constant status-revoked "revoked")
(define-constant status-suspended "suspended")
(define-constant status-expired "expired")

;; Data Variables
(define-data-var next-credential-id uint u1)
(define-data-var next-institution-id uint u1)
(define-data-var verification-fee uint u100000) ;; 0.1 STX in microSTX

;; Data Maps
(define-map institutions principal {
    institution-id: uint,
    name: (string-ascii 200),
    accreditation-body: (string-ascii 100),
    accreditation-number: (string-ascii 50),
    country: (string-ascii 50),
    verified: bool,
    active: bool,
    credentials-issued: uint,
    public-key: (string-ascii 64),
    website: (string-ascii 100),
    established-date: uint,
    created-at: uint
})

(define-map credentials uint {
    student: principal,
    institution: principal,
    credential-type: (string-ascii 20),
    degree-title: (string-ascii 100),
    major-field: (string-ascii 100),
    minor-field: (optional (string-ascii 100)),
    graduation-date: uint,
    gpa: (optional uint), ;; GPA * 100 to avoid decimals
    honors: (optional (string-ascii 50)),
    course-credits: uint,
    document-hash: (string-ascii 64),
    metadata-hash: (string-ascii 64),
    issue-date: uint,
    expiry-date: (optional uint),
    status: (string-ascii 20),
    verification-count: uint
})

(define-map student-credentials principal (list 50 uint))
(define-map institution-credentials principal (list 1000 uint))

(define-map authorized-issuers principal {
    institution: principal,
    name: (string-ascii 100),
    title: (string-ascii 100),
    department: (string-ascii 100),
    authorization-level: uint, ;; 1-5, 5 being highest
    active: bool,
    issued-count: uint,
    authorized-date: uint,
    authorized-by: principal
})

(define-map credential-amendments uint {
    original-credential: uint,
    amendment-type: (string-ascii 50),
    old-value: (string-ascii 200),
    new-value: (string-ascii 200),
    reason: (string-ascii 500),
    amended-by: principal,
    amendment-date: uint,
    approved: bool
})

(define-map batch-issuance uint {
    batch-id: uint,
    institution: principal,
    issuer: principal,
    credential-type: (string-ascii 20),
    graduation-ceremony: (string-ascii 100),
    total-credentials: uint,
    issued-credentials: uint,
    batch-date: uint,
    ceremony-date: uint,
    completed: bool
})

;; Read-only functions
(define-read-only (get-institution (institution principal))
    (map-get? institutions institution)
)

(define-read-only (get-credential (credential-id uint))
    (map-get? credentials credential-id)
)

(define-read-only (get-student-credentials (student principal))
    (default-to (list) (map-get? student-credentials student))
)

(define-read-only (get-institution-credentials (institution principal))
    (default-to (list) (map-get? institution-credentials institution))
)

(define-read-only (get-authorized-issuer (issuer principal))
    (map-get? authorized-issuers issuer)
)

(define-read-only (get-credential-amendment (amendment-id uint))
    (map-get? credential-amendments amendment-id)
)

(define-read-only (get-batch-issuance (batch-id uint))
    (map-get? batch-issuance batch-id)
)

(define-read-only (is-credential-valid (credential-id uint))
    (match (get-credential credential-id)
        credential (let (
            (status (get status credential))
            (expiry (get expiry-date credential))
        )
            (and 
                (is-eq status status-active)
                (match expiry
                    exp-date (> exp-date block-height)
                    true
                )
            )
        )
        false
    )
)

(define-read-only (verify-credential-integrity (credential-id uint) (provided-hash (string-ascii 64)))
    (match (get-credential credential-id)
        credential (is-eq (get document-hash credential) provided-hash)
        false
    )
)

(define-read-only (get-verification-fee)
    (var-get verification-fee)
)

(define-read-only (get-credential-count-by-institution (institution principal))
    (match (get-institution institution)
        inst (get credentials-issued inst)
        u0
    )
)

;; Public functions
(define-public (register-institution (name (string-ascii 200)) (accreditation-body (string-ascii 100)) (accreditation-number (string-ascii 50)) (country (string-ascii 50)) (public-key (string-ascii 64)) (website (string-ascii 100)) (established-date uint))
    (let (
        (institution tx-sender)
        (institution-id (var-get next-institution-id))
    )
        (asserts! (is-none (get-institution institution)) err-already-exists)
        (asserts! (> (len name) u0) err-invalid-input)
        (asserts! (> (len accreditation-number) u0) err-invalid-input)
        
        (map-set institutions institution {
            institution-id: institution-id,
            name: name,
            accreditation-body: accreditation-body,
            accreditation-number: accreditation-number,
            country: country,
            verified: false,
            active: false,
            credentials-issued: u0,
            public-key: public-key,
            website: website,
            established-date: established-date,
            created-at: block-height
        })
        
        (var-set next-institution-id (+ institution-id u1))
        (ok institution-id)
    )
)

(define-public (verify-institution (institution principal))
    (let (
        (inst-data (unwrap! (get-institution institution) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set institutions institution (merge inst-data { verified: true, active: true }))
        (ok institution)
    )
)

(define-public (authorize-issuer (issuer principal) (institution principal) (name (string-ascii 100)) (title (string-ascii 100)) (department (string-ascii 100)) (authorization-level uint))
    (let (
        (inst-data (unwrap! (get-institution institution) err-not-found))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender institution)) err-unauthorized)
        (asserts! (get verified inst-data) err-not-authorized-issuer)
        (asserts! (and (>= authorization-level u1) (<= authorization-level u5)) err-invalid-input)
        
        (map-set authorized-issuers issuer {
            institution: institution,
            name: name,
            title: title,
            department: department,
            authorization-level: authorization-level,
            active: true,
            issued-count: u0,
            authorized-date: block-height,
            authorized-by: tx-sender
        })
        
        (ok issuer)
    )
)

(define-public (issue-credential (student principal) (credential-type (string-ascii 20)) (degree-title (string-ascii 100)) (major-field (string-ascii 100)) (minor-field (optional (string-ascii 100))) (graduation-date uint) (gpa (optional uint)) (honors (optional (string-ascii 50))) (course-credits uint) (document-hash (string-ascii 64)) (metadata-hash (string-ascii 64)) (expiry-date (optional uint)))
    (let (
        (issuer tx-sender)
        (credential-id (var-get next-credential-id))
        (issuer-data (unwrap! (get-authorized-issuer issuer) err-not-authorized-issuer))
        (institution (get institution issuer-data))
        (inst-data (unwrap! (get-institution institution) err-not-found))
        (current-student-creds (get-student-credentials student))
        (current-inst-creds (get-institution-credentials institution))
    )
        (asserts! (get active issuer-data) err-unauthorized)
        (asserts! (get active inst-data) err-not-authorized-issuer)
        (asserts! (> (len degree-title) u0) err-invalid-input)
        (asserts! (> course-credits u0) err-invalid-input)
        
        ;; Validate GPA if provided (0-400 for 0.00-4.00 scale)
        (match gpa
            gpa-val (asserts! (<= gpa-val u400) err-invalid-input)
            true
        )
        
        (map-set credentials credential-id {
            student: student,
            institution: institution,
            credential-type: credential-type,
            degree-title: degree-title,
            major-field: major-field,
            minor-field: minor-field,
            graduation-date: graduation-date,
            gpa: gpa,
            honors: honors,
            course-credits: course-credits,
            document-hash: document-hash,
            metadata-hash: metadata-hash,
            issue-date: block-height,
            expiry-date: expiry-date,
            status: status-active,
            verification-count: u0
        })
        
        ;; Update student credentials list
        (map-set student-credentials student (unwrap! (as-max-len? (append current-student-creds credential-id) u50) err-invalid-input))
        
        ;; Update institution credentials list
        (map-set institution-credentials institution (unwrap! (as-max-len? (append current-inst-creds credential-id) u1000) err-invalid-input))
        
        ;; Update issuer stats
        (map-set authorized-issuers issuer (merge issuer-data { issued-count: (+ (get issued-count issuer-data) u1) }))
        
        ;; Update institution stats
        (map-set institutions institution (merge inst-data { credentials-issued: (+ (get credentials-issued inst-data) u1) }))
        
        (var-set next-credential-id (+ credential-id u1))
        (ok credential-id)
    )
)

(define-public (batch-issue-credentials (batch-id uint) (credential-type (string-ascii 20)) (graduation-ceremony (string-ascii 100)) (ceremony-date uint) (students (list 100 principal)) (degree-data (list 100 { degree-title: (string-ascii 100), major-field: (string-ascii 100), gpa: (optional uint), honors: (optional (string-ascii 50)) })))
    (let (
        (issuer tx-sender)
        (issuer-data (unwrap! (get-authorized-issuer issuer) err-not-authorized-issuer))
        (institution (get institution issuer-data))
        (total-count (len students))
    )
        (asserts! (get active issuer-data) err-unauthorized)
        (asserts! (is-eq (len students) (len degree-data)) err-invalid-input)
        (asserts! (> total-count u0) err-invalid-input)
        
        (map-set batch-issuance batch-id {
            batch-id: batch-id,
            institution: institution,
            issuer: issuer,
            credential-type: credential-type,
            graduation-ceremony: graduation-ceremony,
            total-credentials: total-count,
            issued-credentials: u0,
            batch-date: block-height,
            ceremony-date: ceremony-date,
            completed: false
        })
        
        (ok batch-id)
    )
)

(define-public (revoke-credential (credential-id uint) (reason (string-ascii 500)))
    (let (
        (credential (unwrap! (get-credential credential-id) err-not-found))
        (institution (get institution credential))
        (inst-data (unwrap! (get-institution institution) err-not-found))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender institution)) err-unauthorized)
        (asserts! (is-eq (get status credential) status-active) err-credential-revoked)
        
        (map-set credentials credential-id (merge credential { status: status-revoked }))
        (ok credential-id)
    )
)

(define-public (amend-credential (credential-id uint) (amendment-type (string-ascii 50)) (old-value (string-ascii 200)) (new-value (string-ascii 200)) (reason (string-ascii 500)))
    (let (
        (credential (unwrap! (get-credential credential-id) err-not-found))
        (institution (get institution credential))
        (amendment-id (var-get next-credential-id))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender institution)) err-unauthorized)
        (asserts! (is-eq (get status credential) status-active) err-credential-revoked)
        
        (map-set credential-amendments amendment-id {
            original-credential: credential-id,
            amendment-type: amendment-type,
            old-value: old-value,
            new-value: new-value,
            reason: reason,
            amended-by: tx-sender,
            amendment-date: block-height,
            approved: false
        })
        
        (ok amendment-id)
    )
)

(define-public (approve-amendment (amendment-id uint))
    (let (
        (amendment (unwrap! (get-credential-amendment amendment-id) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set credential-amendments amendment-id (merge amendment { approved: true }))
        (ok amendment-id)
    )
)

(define-public (update-verification-count (credential-id uint))
    (let (
        (credential (unwrap! (get-credential credential-id) err-not-found))
    )
        (map-set credentials credential-id (merge credential { 
            verification-count: (+ (get verification-count credential) u1)
        }))
        (ok credential-id)
    )
)

(define-public (set-verification-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set verification-fee new-fee)
        (ok new-fee)
    )
)

(define-public (deactivate-issuer (issuer principal))
    (let (
        (issuer-data (unwrap! (get-authorized-issuer issuer) err-not-found))
        (institution (get institution issuer-data))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender institution)) err-unauthorized)
        (map-set authorized-issuers issuer (merge issuer-data { active: false }))
        (ok issuer)
    )
)

(define-public (transfer-credential-ownership (credential-id uint) (new-owner principal))
    (let (
        (credential (unwrap! (get-credential credential-id) err-not-found))
        (current-owner (get student credential))
        (current-owner-creds (get-student-credentials current-owner))
        (new-owner-creds (get-student-credentials new-owner))
    )
        (asserts! (is-eq tx-sender current-owner) err-unauthorized)
        (asserts! (is-eq (get status credential) status-active) err-credential-revoked)
        
        ;; Remove from current owner's list
        (map-set student-credentials current-owner (filter credential-not-equal current-owner-creds))
        
        ;; Add to new owner's list
        (map-set student-credentials new-owner (unwrap! (as-max-len? (append new-owner-creds credential-id) u50) err-invalid-input))
        
        ;; Update credential ownership
        (map-set credentials credential-id (merge credential { student: new-owner }))
        
        (ok credential-id)
    )
)

;; Private helper functions
(define-private (credential-not-equal (cred-id uint))
    (not (is-eq cred-id cred-id))
)


;; title: credential-issuance
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

