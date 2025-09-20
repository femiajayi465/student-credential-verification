;; Skill Portfolio Contract
;; Manage comprehensive student skill portfolios and career development

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-invalid-input (err u303))
(define-constant err-already-exists (err u304))
(define-constant err-skill-not-verified (err u305))
(define-constant err-portfolio-private (err u306))
(define-constant err-endorsement-exists (err u307))
(define-constant err-invalid-skill-level (err u308))

;; Skill categories
(define-constant category-technical "technical")
(define-constant category-creative "creative")
(define-constant category-leadership "leadership")
(define-constant category-communication "communication")
(define-constant category-analytical "analytical")
(define-constant category-project-management "project-management")
(define-constant category-language "language")
(define-constant category-soft-skills "soft-skills")

;; Skill levels (0-100 scale)
(define-constant level-beginner u20)
(define-constant level-intermediate u50)
(define-constant level-advanced u75)
(define-constant level-expert u95)

;; Portfolio visibility
(define-constant visibility-private "private")
(define-constant visibility-public "public")
(define-constant visibility-professional "professional")

;; Data Variables
(define-data-var next-portfolio-id uint u1)
(define-data-var next-skill-id uint u1)
(define-data-var next-project-id uint u1)
(define-data-var next-endorsement-id uint u1)

;; Data Maps
(define-map student-portfolios principal {
    portfolio-id: uint,
    owner: principal,
    display-name: (string-ascii 100),
    bio: (string-ascii 500),
    profile-image: (optional (string-ascii 100)),
    contact-email: (optional (string-ascii 100)),
    linkedin-profile: (optional (string-ascii 100)),
    github-profile: (optional (string-ascii 100)),
    portfolio-website: (optional (string-ascii 100)),
    career-objective: (optional (string-ascii 1000)),
    visibility: (string-ascii 20),
    created-at: uint,
    updated-at: uint,
    total-skills: uint,
    total-projects: uint,
    total-endorsements: uint,
    career-level: (string-ascii 20),
    preferred-location: (optional (string-ascii 100))
})

(define-map skills uint {
    skill-id: uint,
    portfolio-owner: principal,
    skill-name: (string-ascii 100),
    skill-category: (string-ascii 50),
    proficiency-level: uint, ;; 0-100
    self-assessed: bool,
    verified: bool,
    verification-source: (optional principal),
    credential-ids: (list 10 uint), ;; Linked credentials
    description: (optional (string-ascii 500)),
    acquired-date: (optional uint),
    last-used: (optional uint),
    years-experience: (optional uint),
    evidence-links: (list 5 (string-ascii 200)),
    created-at: uint,
    updated-at: uint
})

(define-map projects uint {
    project-id: uint,
    portfolio-owner: principal,
    project-title: (string-ascii 200),
    project-description: (string-ascii 1000),
    project-type: (string-ascii 50), ;; academic, personal, professional, open-source
    start-date: uint,
    end-date: (optional uint),
    status: (string-ascii 20), ;; active, completed, paused
    technologies-used: (list 20 (string-ascii 50)),
    skills-demonstrated: (list 15 uint), ;; skill IDs
    project-url: (optional (string-ascii 200)),
    github-repo: (optional (string-ascii 200)),
    demo-url: (optional (string-ascii 200)),
    team-size: (optional uint),
    role: (string-ascii 100),
    achievements: (list 10 (string-ascii 200)),
    media-assets: (list 10 (string-ascii 200)),
    created-at: uint,
    updated-at: uint
})

(define-map endorsements uint {
    endorsement-id: uint,
    endorsed-user: principal,
    endorser: principal,
    skill-id: uint,
    endorsement-type: (string-ascii 50), ;; peer, supervisor, client, mentor
    relationship: (string-ascii 100),
    endorsement-text: (string-ascii 500),
    credibility-score: uint, ;; Based on endorser's profile
    endorsed-at: uint,
    verified: bool,
    endorser-title: (string-ascii 100),
    endorser-organization: (string-ascii 100),
    collaboration-context: (optional (string-ascii 200))
})

(define-map portfolio-skills principal (list 100 uint))
(define-map portfolio-projects principal (list 50 uint))
(define-map portfolio-endorsements principal (list 200 uint))

(define-map skill-endorsements uint (list 20 uint))
(define-map user-connections principal (list 500 principal))

(define-map achievements uint {
    achievement-id: uint,
    portfolio-owner: principal,
    achievement-title: (string-ascii 200),
    achievement-type: (string-ascii 50), ;; award, certification, recognition, milestone
    issuing-organization: (string-ascii 200),
    date-received: uint,
    description: (string-ascii 500),
    verification-url: (optional (string-ascii 200)),
    credential-id: (optional uint),
    significance-level: uint, ;; 1-5
    public-visibility: bool
})

(define-map career-goals principal {
    short-term-goals: (list 5 (string-ascii 200)),
    long-term-goals: (list 3 (string-ascii 200)),
    target-roles: (list 5 (string-ascii 100)),
    preferred-industries: (list 5 (string-ascii 100)),
    skill-development-plan: (list 10 (string-ascii 200)),
    target-salary-range: (optional (string-ascii 50)),
    geographic-preferences: (list 5 (string-ascii 100)),
    updated-at: uint
})

;; Read-only functions
(define-read-only (get-portfolio (portfolio-owner principal))
    (map-get? student-portfolios portfolio-owner)
)

(define-read-only (get-skill (skill-id uint))
    (map-get? skills skill-id)
)

(define-read-only (get-project (project-id uint))
    (map-get? projects project-id)
)

(define-read-only (get-endorsement (endorsement-id uint))
    (map-get? endorsements endorsement-id)
)

(define-read-only (get-portfolio-skills (portfolio-owner principal))
    (default-to (list) (map-get? portfolio-skills portfolio-owner))
)

(define-read-only (get-portfolio-projects (portfolio-owner principal))
    (default-to (list) (map-get? portfolio-projects portfolio-owner))
)

(define-read-only (get-portfolio-endorsements (portfolio-owner principal))
    (default-to (list) (map-get? portfolio-endorsements portfolio-owner))
)

(define-read-only (get-skill-endorsements (skill-id uint))
    (default-to (list) (map-get? skill-endorsements skill-id))
)

(define-read-only (get-user-connections (user principal))
    (default-to (list) (map-get? user-connections user))
)

(define-read-only (get-achievement (achievement-id uint))
    (map-get? achievements achievement-id)
)

(define-read-only (get-career-goals (user principal))
    (map-get? career-goals user)
)

(define-read-only (is-portfolio-public (portfolio-owner principal))
    (match (get-portfolio portfolio-owner)
        portfolio (not (is-eq (get visibility portfolio) visibility-private))
        false
    )
)

(define-read-only (get-skill-summary (portfolio-owner principal))
    (let (
        (skills-list (get-portfolio-skills portfolio-owner))
        (verified-skills (len (filter is-skill-verified skills-list)))
        (total-skills (len skills-list))
    )
        {
            total-skills: total-skills,
            verified-skills: verified-skills,
            verification-rate: (if (> total-skills u0) (/ (* verified-skills u100) total-skills) u0)
        }
    )
)

(define-read-only (get-endorsement-stats (portfolio-owner principal))
    (let (
        (endorsements-list (get-portfolio-endorsements portfolio-owner))
        (total-endorsements (len endorsements-list))
        (verified-endorsements (len (filter is-endorsement-verified endorsements-list)))
    )
        {
            total-endorsements: total-endorsements,
            verified-endorsements: verified-endorsements,
            credibility-score: (calculate-portfolio-credibility portfolio-owner)
        }
    )
)

;; Public functions
(define-public (create-portfolio (display-name (string-ascii 100)) (bio (string-ascii 500)) (career-objective (optional (string-ascii 1000))) (visibility (string-ascii 20)))
    (let (
        (portfolio-owner tx-sender)
        (portfolio-id (var-get next-portfolio-id))
    )
        (asserts! (is-none (get-portfolio portfolio-owner)) err-already-exists)
        (asserts! (> (len display-name) u0) err-invalid-input)
        (asserts! (or (is-eq visibility visibility-private)
                     (is-eq visibility visibility-public)
                     (is-eq visibility visibility-professional)) err-invalid-input)
        
        (map-set student-portfolios portfolio-owner {
            portfolio-id: portfolio-id,
            owner: portfolio-owner,
            display-name: display-name,
            bio: bio,
            profile-image: none,
            contact-email: none,
            linkedin-profile: none,
            github-profile: none,
            portfolio-website: none,
            career-objective: career-objective,
            visibility: visibility,
            created-at: block-height,
            updated-at: block-height,
            total-skills: u0,
            total-projects: u0,
            total-endorsements: u0,
            career-level: "entry",
            preferred-location: none
        })
        
        (var-set next-portfolio-id (+ portfolio-id u1))
        (ok portfolio-id)
    )
)

(define-public (update-portfolio (display-name (optional (string-ascii 100))) (bio (optional (string-ascii 500))) (profile-image (optional (string-ascii 100))) (contact-email (optional (string-ascii 100))) (linkedin-profile (optional (string-ascii 100))) (github-profile (optional (string-ascii 100))) (portfolio-website (optional (string-ascii 100))) (career-objective (optional (string-ascii 1000))) (visibility (optional (string-ascii 20))) (career-level (optional (string-ascii 20))) (preferred-location (optional (string-ascii 100))))
    (let (
        (portfolio-owner tx-sender)
        (current-portfolio (unwrap! (get-portfolio portfolio-owner) err-not-found))
    )
        (map-set student-portfolios portfolio-owner (merge current-portfolio {
            display-name: (default-to (get display-name current-portfolio) display-name),
            bio: (default-to (get bio current-portfolio) bio),
            profile-image: (match profile-image new-image (some new-image) (get profile-image current-portfolio)),
            contact-email: (match contact-email new-email (some new-email) (get contact-email current-portfolio)),
            linkedin-profile: (match linkedin-profile new-linkedin (some new-linkedin) (get linkedin-profile current-portfolio)),
            github-profile: (match github-profile new-github (some new-github) (get github-profile current-portfolio)),
            portfolio-website: (match portfolio-website new-website (some new-website) (get portfolio-website current-portfolio)),
            career-objective: (match career-objective new-objective (some new-objective) (get career-objective current-portfolio)),
            visibility: (default-to (get visibility current-portfolio) visibility),
            career-level: (default-to (get career-level current-portfolio) career-level),
            preferred-location: (match preferred-location new-location (some new-location) (get preferred-location current-portfolio)),
            updated-at: block-height
        }))
        
        (ok portfolio-owner)
    )
)

(define-public (add-skill (skill-name (string-ascii 100)) (skill-category (string-ascii 50)) (proficiency-level uint) (description (optional (string-ascii 500))) (acquired-date (optional uint)) (years-experience (optional uint)) (evidence-links (list 5 (string-ascii 200))))
    (let (
        (portfolio-owner tx-sender)
        (skill-id (var-get next-skill-id))
        (current-portfolio (unwrap! (get-portfolio portfolio-owner) err-not-found))
        (current-skills (get-portfolio-skills portfolio-owner))
    )
        (asserts! (> (len skill-name) u0) err-invalid-input)
        (asserts! (and (>= proficiency-level u0) (<= proficiency-level u100)) err-invalid-skill-level)
        
        (map-set skills skill-id {
            skill-id: skill-id,
            portfolio-owner: portfolio-owner,
            skill-name: skill-name,
            skill-category: skill-category,
            proficiency-level: proficiency-level,
            self-assessed: true,
            verified: false,
            verification-source: none,
            credential-ids: (list),
            description: description,
            acquired-date: acquired-date,
            last-used: (some block-height),
            years-experience: years-experience,
            evidence-links: evidence-links,
            created-at: block-height,
            updated-at: block-height
        })
        
        ;; Update portfolio skills list
        (map-set portfolio-skills portfolio-owner 
            (unwrap! (as-max-len? (append current-skills skill-id) u100) err-invalid-input))
        
        ;; Update portfolio total skills count
        (map-set student-portfolios portfolio-owner 
            (merge current-portfolio { 
                total-skills: (+ (get total-skills current-portfolio) u1),
                updated-at: block-height 
            }))
        
        (var-set next-skill-id (+ skill-id u1))
        (ok skill-id)
    )
)

(define-public (add-project (project-title (string-ascii 200)) (project-description (string-ascii 1000)) (project-type (string-ascii 50)) (start-date uint) (end-date (optional uint)) (technologies-used (list 20 (string-ascii 50))) (skills-demonstrated (list 15 uint)) (project-url (optional (string-ascii 200))) (github-repo (optional (string-ascii 200))) (demo-url (optional (string-ascii 200))) (team-size (optional uint)) (role (string-ascii 100)) (project-achievements (list 10 (string-ascii 200))))
    (let (
        (portfolio-owner tx-sender)
        (project-id (var-get next-project-id))
        (current-portfolio (unwrap! (get-portfolio portfolio-owner) err-not-found))
        (current-projects (get-portfolio-projects portfolio-owner))
        (project-status (if (is-some end-date) "completed" "active"))
    )
        (asserts! (> (len project-title) u0) err-invalid-input)
        (asserts! (> (len role) u0) err-invalid-input)
        
        (map-set projects project-id {
            project-id: project-id,
            portfolio-owner: portfolio-owner,
            project-title: project-title,
            project-description: project-description,
            project-type: project-type,
            start-date: start-date,
            end-date: end-date,
            status: project-status,
            technologies-used: technologies-used,
            skills-demonstrated: skills-demonstrated,
            project-url: project-url,
            github-repo: github-repo,
            demo-url: demo-url,
            team-size: team-size,
            role: role,
            achievements: project-achievements,
            media-assets: (list),
            created-at: block-height,
            updated-at: block-height
        })
        
        ;; Update portfolio projects list
        (map-set portfolio-projects portfolio-owner
            (unwrap! (as-max-len? (append current-projects project-id) u50) err-invalid-input))
        
        ;; Update portfolio total projects count
        (map-set student-portfolios portfolio-owner
            (merge current-portfolio {
                total-projects: (+ (get total-projects current-portfolio) u1),
                updated-at: block-height
            }))
        
        (var-set next-project-id (+ project-id u1))
        (ok project-id)
    )
)

(define-public (endorse-skill (endorsed-user principal) (skill-id uint) (endorsement-type (string-ascii 50)) (relationship (string-ascii 100)) (endorsement-text (string-ascii 500)) (endorser-title (string-ascii 100)) (endorser-organization (string-ascii 100)) (collaboration-context (optional (string-ascii 200))))
    (let (
        (endorser tx-sender)
        (endorsement-id (var-get next-endorsement-id))
        (skill (unwrap! (get-skill skill-id) err-not-found))
        (current-endorsements (get-portfolio-endorsements endorsed-user))
        (current-skill-endorsements (get-skill-endorsements skill-id))
        (current-portfolio (unwrap! (get-portfolio endorsed-user) err-not-found))
    )
        (asserts! (is-eq (get portfolio-owner skill) endorsed-user) err-not-found)
        (asserts! (not (is-eq endorser endorsed-user)) err-invalid-input)
        (asserts! (> (len endorsement-text) u0) err-invalid-input)
        
        ;; Check if endorsement already exists
        (asserts! (is-none (index-of current-skill-endorsements endorsement-id)) err-endorsement-exists)
        
        (map-set endorsements endorsement-id {
            endorsement-id: endorsement-id,
            endorsed-user: endorsed-user,
            endorser: endorser,
            skill-id: skill-id,
            endorsement-type: endorsement-type,
            relationship: relationship,
            endorsement-text: endorsement-text,
            credibility-score: (calculate-endorser-credibility endorser),
            endorsed-at: block-height,
            verified: false,
            endorser-title: endorser-title,
            endorser-organization: endorser-organization,
            collaboration-context: collaboration-context
        })
        
        ;; Update portfolio endorsements list
        (map-set portfolio-endorsements endorsed-user
            (unwrap! (as-max-len? (append current-endorsements endorsement-id) u200) err-invalid-input))
        
        ;; Update skill endorsements list
        (map-set skill-endorsements skill-id
            (unwrap! (as-max-len? (append current-skill-endorsements endorsement-id) u20) err-invalid-input))
        
        ;; Update portfolio total endorsements count
        (map-set student-portfolios endorsed-user
            (merge current-portfolio {
                total-endorsements: (+ (get total-endorsements current-portfolio) u1),
                updated-at: block-height
            }))
        
        (var-set next-endorsement-id (+ endorsement-id u1))
        (ok endorsement-id)
    )
)

(define-public (verify-skill (skill-id uint) (verification-source principal) (credential-ids (list 10 uint)))
    (let (
        (skill (unwrap! (get-skill skill-id) err-not-found))
    )
        (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender verification-source)) err-unauthorized)
        
        (map-set skills skill-id (merge skill {
            verified: true,
            verification-source: (some verification-source),
            credential-ids: credential-ids,
            updated-at: block-height
        }))
        
        (ok skill-id)
    )
)

(define-public (connect-with-user (target-user principal))
    (let (
        (user tx-sender)
        (current-connections (get-user-connections user))
    )
        (asserts! (not (is-eq user target-user)) err-invalid-input)
        (asserts! (is-some (get-portfolio target-user)) err-not-found)
        (asserts! (is-none (index-of current-connections target-user)) err-already-exists)
        
        (map-set user-connections user
            (unwrap! (as-max-len? (append current-connections target-user) u500) err-invalid-input))
        
        (ok target-user)
    )
)

(define-public (set-career-goals (short-term-goals (list 5 (string-ascii 200))) (long-term-goals (list 3 (string-ascii 200))) (target-roles (list 5 (string-ascii 100))) (preferred-industries (list 5 (string-ascii 100))) (skill-development-plan (list 10 (string-ascii 200))) (target-salary-range (optional (string-ascii 50))) (geographic-preferences (list 5 (string-ascii 100))))
    (let (
        (user tx-sender)
    )
        (asserts! (is-some (get-portfolio user)) err-not-found)
        
        (map-set career-goals user {
            short-term-goals: short-term-goals,
            long-term-goals: long-term-goals,
            target-roles: target-roles,
            preferred-industries: preferred-industries,
            skill-development-plan: skill-development-plan,
            target-salary-range: target-salary-range,
            geographic-preferences: geographic-preferences,
            updated-at: block-height
        })
        
        (ok user)
    )
)

(define-public (update-skill-proficiency (skill-id uint) (new-level uint) (evidence-links (list 5 (string-ascii 200))))
    (let (
        (skill (unwrap! (get-skill skill-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get portfolio-owner skill)) err-unauthorized)
        (asserts! (and (>= new-level u0) (<= new-level u100)) err-invalid-skill-level)
        
        (map-set skills skill-id (merge skill {
            proficiency-level: new-level,
            evidence-links: evidence-links,
            last-used: (some block-height),
            updated-at: block-height
        }))
        
        (ok skill-id)
    )
)

;; Private helper functions
(define-private (is-skill-verified (skill-id uint))
    (match (get-skill skill-id)
        skill (get verified skill)
        false
    )
)

(define-private (is-endorsement-verified (endorsement-id uint))
    (match (get-endorsement endorsement-id)
        endorsement (get verified endorsement)
        false
    )
)

(define-private (calculate-endorser-credibility (endorser principal))
    ;; Simple credibility calculation based on portfolio existence and connections
    (match (get-portfolio endorser)
        portfolio (let (
            (connections-count (len (get-user-connections endorser)))
            (endorsements-count (get total-endorsements portfolio))
        )
            (+ u50 (if (< connections-count u30) connections-count u30) (if (< endorsements-count u20) endorsements-count u20))
        )
        u25 ;; Base credibility for non-portfolio users
    )
)

(define-private (calculate-portfolio-credibility (portfolio-owner principal))
    (let (
        (endorsements-list (get-portfolio-endorsements portfolio-owner))
        (total-credibility (fold + (map get-endorsement-credibility endorsements-list) u0))
        (endorsement-count (len endorsements-list))
    )
        (if (> endorsement-count u0)
            (/ total-credibility endorsement-count)
            u0
        )
    )
)

(define-private (get-endorsement-credibility (endorsement-id uint))
    (match (get-endorsement endorsement-id)
        endorsement (get credibility-score endorsement)
        u0
    )
)


;; title: skill-portfolio
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

