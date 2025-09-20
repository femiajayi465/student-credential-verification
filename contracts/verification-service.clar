;; Verification Service Contract
;; Comprehensive verification and validation of academic credentials

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-invalid-input (err u203))
(define-constant err-already-exists (err u204))
(define-constant err-insufficient-payment (err u205))
(define-constant err-verification-failed (err u206))
(define-constant err-invalid-verifier (err u207))
(define-constant err-expired-request (err u208))

;; Verification request status
(define-constant status-pending "pending")
(define-constant status-in-progress "in-progress")
(define-constant status-verified "verified")
(define-constant status-rejected "rejected")
(define-constant status-expired "expired")

;; Verification types
(define-constant type-basic "basic")
(define-constant type-enhanced "enhanced")
(define-constant type-forensic "forensic")
(define-constant type-blockchain "blockchain")
(define-constant type-institutional "institutional")

;; Data Variables
(define-data-var next-request-id uint u1)
(define-data-var next-verifier-id uint u1)
(define-data-var basic-verification-fee uint u50000) ;; 0.05 STX
(define-data-var enhanced-verification-fee uint u200000) ;; 0.2 STX
(define-data-var forensic-verification-fee uint u500000) ;; 0.5 STX
(define-data-var request-timeout-blocks uint u144) ;; ~24 hours

;; Data Maps
(define-map verification-requests uint {
    requester: principal,
    credential-id: uint,
    verification-type: (string-ascii 20),
    verifier: (optional principal),
    status: (string-ascii 20),
    priority-level: uint, ;; 1-5, 5 being highest
    requested-at: uint,
    assigned-at: (optional uint),
    completed-at: (optional uint),
    deadline: uint,
    payment-amount: uint,
    verification-result: (optional bool),
    confidence-score: (optional uint), ;; 0-100
    verification-details: (optional (string-ascii 1000)),
    digital-signature: (optional (string-ascii 128)),
    verification-hash: (optional (string-ascii 64))
})

(define-map certified-verifiers principal {
    verifier-id: uint,
    name: (string-ascii 100),
    organization: (string-ascii 100),
    specializations: (list 10 (string-ascii 50)),
    certification-level: uint, ;; 1-5
    reputation-score: uint, ;; 0-1000
    verifications-completed: uint,
    verifications-rejected: uint,
    average-completion-time: uint,
    active: bool,
    certified-date: uint,
    last-activity: uint,
    contact-info: (string-ascii 200)
})

(define-map verifier-assignments uint {
    request-id: uint,
    verifier: principal,
    assigned-at: uint,
    estimated-completion: uint,
    notes: (optional (string-ascii 500))
})

(define-map verification-evidence uint {
    request-id: uint,
    evidence-type: (string-ascii 50),
    evidence-hash: (string-ascii 64),
    uploaded-by: principal,
    uploaded-at: uint,
    verified: bool,
    description: (string-ascii 500)
})

(define-map requester-history principal (list 100 uint))
(define-map verifier-assignments-history principal (list 200 uint))

(define-map dispute-cases uint {
    request-id: uint,
    disputant: principal,
    dispute-type: (string-ascii 50),
    reason: (string-ascii 1000),
    supporting-evidence: (optional (string-ascii 64)),
    filed-at: uint,
    status: (string-ascii 20),
    resolution: (optional (string-ascii 1000)),
    resolved-at: (optional uint),
    resolved-by: (optional principal)
})

(define-map verification-templates (string-ascii 50) {
    template-name: (string-ascii 50),
    required-fields: (list 20 (string-ascii 50)),
    verification-steps: (list 10 (string-ascii 100)),
    estimated-time: uint,
    minimum-verifier-level: uint,
    template-fee: uint
})

;; Read-only functions
(define-read-only (get-verification-request (request-id uint))
    (map-get? verification-requests request-id)
)

(define-read-only (get-certified-verifier (verifier principal))
    (map-get? certified-verifiers verifier)
)

(define-read-only (get-verifier-assignment (assignment-id uint))
    (map-get? verifier-assignments assignment-id)
)

(define-read-only (get-verification-evidence (evidence-id uint))
    (map-get? verification-evidence evidence-id)
)

(define-read-only (get-requester-history (requester principal))
    (default-to (list) (map-get? requester-history requester))
)

(define-read-only (get-verifier-history (verifier principal))
    (default-to (list) (map-get? verifier-assignments-history verifier))
)

(define-read-only (get-dispute-case (dispute-id uint))
    (map-get? dispute-cases dispute-id)
)

(define-read-only (get-verification-template (template-type (string-ascii 50)))
    (map-get? verification-templates template-type)
)

(define-read-only (get-verification-fees)
    {
        basic: (var-get basic-verification-fee),
        enhanced: (var-get enhanced-verification-fee),
        forensic: (var-get forensic-verification-fee)
    }
)

(define-read-only (is-request-expired (request-id uint))
    (match (get-verification-request request-id)
        request (> block-height (get deadline request))
        false
    )
)

(define-read-only (get-verifier-workload (verifier principal))
    (let (
        (assignments (get-verifier-history verifier))
        (pending-count (len (filter is-assignment-pending assignments)))
    )
        pending-count
    )
)

(define-read-only (calculate-verification-fee (verification-type (string-ascii 20)) (priority-level uint))
    (let (
        (base-fee (if (is-eq verification-type type-basic)
            (var-get basic-verification-fee)
            (if (is-eq verification-type type-enhanced)
                (var-get enhanced-verification-fee)
                (if (is-eq verification-type type-forensic)
                    (var-get forensic-verification-fee)
                    (var-get basic-verification-fee)
                )
            )
        ))
        (priority-multiplier (if (is-eq priority-level u5)
            u200 ;; 2x for urgent
            (if (is-eq priority-level u4)
                u150 ;; 1.5x for high
                (if (is-eq priority-level u3)
                    u125 ;; 1.25x for medium
                    (if (is-eq priority-level u2)
                        u110 ;; 1.1x for normal
                        u100 ;; 1x for low
                    )
                )
            )
        ))
    )
        (/ (* base-fee priority-multiplier) u100)
    )
)

;; Public functions
(define-public (register-verifier (name (string-ascii 100)) (organization (string-ascii 100)) (specializations (list 10 (string-ascii 50))) (certification-level uint) (contact-info (string-ascii 200)))
    (let (
        (verifier tx-sender)
        (verifier-id (var-get next-verifier-id))
    )
        (asserts! (is-none (get-certified-verifier verifier)) err-already-exists)
        (asserts! (> (len name) u0) err-invalid-input)
        (asserts! (and (>= certification-level u1) (<= certification-level u5)) err-invalid-input)
        
        (map-set certified-verifiers verifier {
            verifier-id: verifier-id,
            name: name,
            organization: organization,
            specializations: specializations,
            certification-level: certification-level,
            reputation-score: u500, ;; Starting reputation
            verifications-completed: u0,
            verifications-rejected: u0,
            average-completion-time: u0,
            active: false, ;; Needs approval
            certified-date: block-height,
            last-activity: block-height,
            contact-info: contact-info
        })
        
        (var-set next-verifier-id (+ verifier-id u1))
        (ok verifier-id)
    )
)

(define-public (approve-verifier (verifier principal))
    (let (
        (verifier-data (unwrap! (get-certified-verifier verifier) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set certified-verifiers verifier (merge verifier-data { active: true }))
        (ok verifier)
    )
)

(define-public (request-verification (credential-id uint) (verification-type (string-ascii 20)) (priority-level uint))
    (let (
        (request-id (var-get next-request-id))
        (requester tx-sender)
        (fee (calculate-verification-fee verification-type priority-level))
        (deadline (+ block-height (var-get request-timeout-blocks)))
        (current-history (get-requester-history requester))
    )
        (asserts! (and (>= priority-level u1) (<= priority-level u5)) err-invalid-input)
        (asserts! (or (is-eq verification-type type-basic) 
                     (is-eq verification-type type-enhanced)
                     (is-eq verification-type type-forensic)
                     (is-eq verification-type type-blockchain)
                     (is-eq verification-type type-institutional)) err-invalid-input)
        
        ;; Payment handling would be implemented here
        ;; (try! (stx-transfer? fee requester (as-contract tx-sender)))
        
        (map-set verification-requests request-id {
            requester: requester,
            credential-id: credential-id,
            verification-type: verification-type,
            verifier: none,
            status: status-pending,
            priority-level: priority-level,
            requested-at: block-height,
            assigned-at: none,
            completed-at: none,
            deadline: deadline,
            payment-amount: fee,
            verification-result: none,
            confidence-score: none,
            verification-details: none,
            digital-signature: none,
            verification-hash: none
        })
        
        ;; Update requester history
        (map-set requester-history requester 
            (unwrap! (as-max-len? (append current-history request-id) u100) err-invalid-input))
        
        (var-set next-request-id (+ request-id u1))
        (ok request-id)
    )
)

(define-public (assign-verification (request-id uint) (verifier principal))
    (let (
        (request (unwrap! (get-verification-request request-id) err-not-found))
        (verifier-data (unwrap! (get-certified-verifier verifier) err-not-found))
        (current-verifier-history (get-verifier-history verifier))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender verifier)) err-unauthorized)
        (asserts! (is-eq (get status request) status-pending) err-invalid-input)
        (asserts! (get active verifier-data) err-invalid-verifier)
        (asserts! (not (is-request-expired request-id)) err-expired-request)
        
        ;; Update request status
        (map-set verification-requests request-id (merge request {
            verifier: (some verifier),
            status: status-in-progress,
            assigned-at: (some block-height)
        }))
        
        ;; Create assignment record
        (map-set verifier-assignments request-id {
            request-id: request-id,
            verifier: verifier,
            assigned-at: block-height,
            estimated-completion: (+ block-height u72), ;; ~12 hours
            notes: none
        })
        
        ;; Update verifier history
        (map-set verifier-assignments-history verifier
            (unwrap! (as-max-len? (append current-verifier-history request-id) u200) err-invalid-input))
        
        (ok request-id)
    )
)

(define-public (submit-verification-result (request-id uint) (result bool) (confidence-score uint) (verification-details (string-ascii 1000)) (digital-signature (string-ascii 128)) (verification-hash (string-ascii 64)))
    (let (
        (request (unwrap! (get-verification-request request-id) err-not-found))
        (verifier tx-sender)
        (verifier-data (unwrap! (get-certified-verifier verifier) err-not-found))
    )
        (asserts! (is-eq (get status request) status-in-progress) err-invalid-input)
        (asserts! (match (get verifier request)
            assigned-verifier (is-eq assigned-verifier verifier)
            false
        ) err-unauthorized)
        (asserts! (<= confidence-score u100) err-invalid-input)
        (asserts! (not (is-request-expired request-id)) err-expired-request)
        
        ;; Update request with results
        (map-set verification-requests request-id (merge request {
            status: (if result status-verified status-rejected),
            completed-at: (some block-height),
            verification-result: (some result),
            confidence-score: (some confidence-score),
            verification-details: (some verification-details),
            digital-signature: (some digital-signature),
            verification-hash: (some verification-hash)
        }))
        
        ;; Update verifier stats
        (map-set certified-verifiers verifier (merge verifier-data {
            verifications-completed: (if result 
                (+ (get verifications-completed verifier-data) u1)
                (get verifications-completed verifier-data)),
            verifications-rejected: (if result
                (get verifications-rejected verifier-data)
                (+ (get verifications-rejected verifier-data) u1)),
            last-activity: block-height
        }))
        
        (ok request-id)
    )
)

(define-public (upload-verification-evidence (request-id uint) (evidence-type (string-ascii 50)) (evidence-hash (string-ascii 64)) (description (string-ascii 500)))
    (let (
        (request (unwrap! (get-verification-request request-id) err-not-found))
        (evidence-id (var-get next-request-id)) ;; Reusing counter for simplicity
    )
        (asserts! (or (is-eq tx-sender (get requester request))
                     (match (get verifier request)
                        assigned-verifier (is-eq tx-sender assigned-verifier)
                        false
                     )) err-unauthorized)
        
        (map-set verification-evidence evidence-id {
            request-id: request-id,
            evidence-type: evidence-type,
            evidence-hash: evidence-hash,
            uploaded-by: tx-sender,
            uploaded-at: block-height,
            verified: false,
            description: description
        })
        
        (ok evidence-id)
    )
)

(define-public (file-dispute (request-id uint) (dispute-type (string-ascii 50)) (reason (string-ascii 1000)) (supporting-evidence (optional (string-ascii 64))))
    (let (
        (request (unwrap! (get-verification-request request-id) err-not-found))
        (dispute-id request-id) ;; Using request-id as dispute-id for simplicity
    )
        (asserts! (is-eq tx-sender (get requester request)) err-unauthorized)
        (asserts! (or (is-eq (get status request) status-verified) 
                     (is-eq (get status request) status-rejected)) err-invalid-input)
        
        (map-set dispute-cases dispute-id {
            request-id: request-id,
            disputant: tx-sender,
            dispute-type: dispute-type,
            reason: reason,
            supporting-evidence: supporting-evidence,
            filed-at: block-height,
            status: status-pending,
            resolution: none,
            resolved-at: none,
            resolved-by: none
        })
        
        (ok dispute-id)
    )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 1000)))
    (let (
        (dispute (unwrap! (get-dispute-case dispute-id) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status dispute) status-pending) err-invalid-input)
        
        (map-set dispute-cases dispute-id (merge dispute {
            status: "resolved",
            resolution: (some resolution),
            resolved-at: (some block-height),
            resolved-by: (some tx-sender)
        }))
        
        (ok dispute-id)
    )
)

(define-public (update-verification-fees (basic-fee uint) (enhanced-fee uint) (forensic-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set basic-verification-fee basic-fee)
        (var-set enhanced-verification-fee enhanced-fee)
        (var-set forensic-verification-fee forensic-fee)
        (ok true)
    )
)

(define-public (set-request-timeout (timeout-blocks uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> timeout-blocks u0) err-invalid-input)
        (var-set request-timeout-blocks timeout-blocks)
        (ok timeout-blocks)
    )
)

(define-public (deactivate-verifier (verifier principal))
    (let (
        (verifier-data (unwrap! (get-certified-verifier verifier) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set certified-verifiers verifier (merge verifier-data { active: false }))
        (ok verifier)
    )
)

;; Private helper functions
(define-private (is-assignment-pending (request-id uint))
    (match (get-verification-request request-id)
        request (is-eq (get status request) status-in-progress)
        false
    )
)


;; title: verification-service
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

