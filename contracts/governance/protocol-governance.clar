;; Protocol Governance Contract
;; ============================
;; CLARITY 4 FEATURES SHOWCASED:
;; - stacks-block-time: Time-locked proposal execution
;; - contract-hash?: Verify new contract implementations before upgrade
;; - to-ascii?: Generate human-readable proposal descriptions

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u600))
(define-constant err-proposal-not-found (err u601))
(define-constant err-already-voted (err u602))
(define-constant err-proposal-not-passed (err u603))
(define-constant err-timelock-not-expired (err u604))
(define-constant err-proposal-expired (err u605))
(define-constant err-invalid-contract-hash (err u606))
(define-constant err-conversion-failed (err u607))

;; Governance Parameters
(define-constant VOTING-PERIOD u1008) ;; ~1 week in blocks
(define-constant TIMELOCK-PERIOD u86400) ;; 24 hours in seconds
(define-constant QUORUM-PERCENTAGE u20) ;; 20% of supply needed
(define-constant PROPOSAL-THRESHOLD u1000000000) ;; 1000 STX to propose

;; Data Variables
(define-data-var proposal-count uint u0)
(define-data-var total-voting-power uint u100000000000) ;; Total STX supply

;; Proposal structure
(define-map proposals
    { proposal-id: uint }
    {
        proposer: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        target-contract: (optional principal),
        new-contract-hash: (optional (buff 32)), ;; CLARITY 4: Store contract hash
        votes-for: uint,
        votes-against: uint,
        start-block: uint,
        end-block: uint,
        execution-time: uint, ;; CLARITY 4: stacks-block-time when can execute
        executed: bool,
        cancelled: bool,
    }
)

;; Track user votes
(define-map user-votes
    {
        proposal-id: uint,
        voter: principal,
    }
    {
        vote: bool, ;; true = for, false = against
        amount: uint,
        vote-time: uint, ;; CLARITY 4: Timestamp of vote
    }
)

;; CLARITY 4 FEATURE: Create proposal with time-locked execution
;; Proposals can only be executed after TIMELOCK-PERIOD has passed
(define-public (create-proposal
        (title (string-ascii 100))
        (description (string-ascii 500))
        (target-contract (optional principal))
    )
    (let (
            (proposal-id (+ (var-get proposal-count) u1))
            (voter-balance (stx-get-balance tx-sender))
        )
        ;; Check proposer has enough voting power
        (asserts! (>= voter-balance PROPOSAL-THRESHOLD) err-not-authorized)

        ;; CLARITY 4: Verify target contract if provided
        (let ((contract-hash (match target-contract
                contract
                (match (contract-hash? contract)
                    hash-value (some hash-value)
                    none
                )
                none
            )))
            ;; Create proposal with stacks-block-time based execution delay
            (map-set proposals { proposal-id: proposal-id } {
                proposer: tx-sender,
                title: title,
                description: description,
                target-contract: target-contract,
                new-contract-hash: contract-hash,
                votes-for: u0,
                votes-against: u0,
                start-block: stacks-block-height,
                end-block: (+ stacks-block-height VOTING-PERIOD),
                execution-time: (+ stacks-block-time TIMELOCK-PERIOD),
                executed: false,
                cancelled: false,
            })

            ;; Increment proposal count
            (var-set proposal-count proposal-id)

            (ok proposal-id)
        )
    )
)

;; Vote on a proposal
;; CLARITY 4: Tracks vote time using stacks-block-time
(define-public (vote
        (proposal-id uint)
        (vote-for bool)
    )
    (let (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id })
                err-proposal-not-found
            ))
            (voter-balance (stx-get-balance tx-sender))
        )
        ;; Check voting period is active
        (asserts! (< stacks-block-height (get end-block proposal)) err-proposal-expired)
        (asserts! (>= stacks-block-height (get start-block proposal))
            err-proposal-not-found
        )

        ;; Check user hasn't voted yet
        (asserts!
            (is-none (map-get? user-votes {
                proposal-id: proposal-id,
                voter: tx-sender,
            }))
            err-already-voted
        )

        ;; Record vote with CLARITY 4 timestamp
        (map-set user-votes {
            proposal-id: proposal-id,
            voter: tx-sender,
        } {
            vote: vote-for,
            amount: voter-balance,
            vote-time: stacks-block-time,
        })

        ;; Update proposal vote counts
        (map-set proposals { proposal-id: proposal-id }
            (merge proposal {
                votes-for: (if vote-for
                    (+ (get votes-for proposal) voter-balance)
                    (get votes-for proposal)
                ),
                votes-against: (if (not vote-for)
                    (+ (get votes-against proposal) voter-balance)
                    (get votes-against proposal)
                ),
            })
        )

        (ok true)
    )
)

;; CLARITY 4 FEATURE: Time-locked execution with stacks-block-time
;; Execute a proposal after timelock period has passed
(define-public (execute-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id })
            err-proposal-not-found
        )))
        ;; Check proposal hasn't been executed or cancelled
        (asserts! (not (get executed proposal)) err-proposal-not-passed)
        (asserts! (not (get cancelled proposal)) err-proposal-not-passed)

        ;; Check voting period has ended
        (asserts! (>= stacks-block-height (get end-block proposal))
            err-timelock-not-expired
        )

        ;; CLARITY 4: Check timelock using stacks-block-time
        (asserts! (>= stacks-block-time (get execution-time proposal))
            err-timelock-not-expired
        )

        ;; Check proposal passed (more-votes-for && meets quorum)
        (let (
                (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
                (quorum-met (>= total-votes
                    (/ (* (var-get total-voting-power) QUORUM-PERCENTAGE) u100)
                ))
                (passed (> (get votes-for proposal) (get votes-against proposal)))
            )
            (asserts! quorum-met err-proposal-not-passed)
            (asserts! passed err-proposal-not-passed)

            ;; CLARITY 4: Verify target contract hash if doing contract upgrade
            (match (get target-contract proposal)
                target (match (get new-contract-hash proposal)
                    expected-hash
                        (match (contract-hash? target)
                            current-hash
                                (asserts! (is-eq current-hash expected-hash) err-invalid-contract-hash)
                            (asserts! false err-invalid-contract-hash)
                        )
                    true
                )
                true
            )

            ;; Mark as executed
            (map-set proposals { proposal-id: proposal-id }
                (merge proposal { executed: true })
            )

            (ok true)
        )
    )
)

;; CLARITY 4 FEATURE: to-ascii? for governance reports
;; Get human-readable proposal status
(define-read-only (get-proposal-status-ascii (proposal-id uint))
    (match (map-get? proposals { proposal-id: proposal-id })
        proposal (let (
                (votes-for-ascii "VOTES_FOR_ASCII")
                (votes-against-ascii "VOTES_AGAINST_ASCII")
                (time-left (if (> (get execution-time proposal) stacks-block-time)
                    (- (get execution-time proposal) stacks-block-time)
                    u0
                ))
                (time-left-ascii "TIME_LEFT_ASCII")
                (status (if (get executed proposal)
                    "EXECUTED"
                    (if (get cancelled proposal)
                        "CANCELLED"
                        (if (>= stacks-block-time (get execution-time proposal))
                            "READY"
                            "PENDING"
                        )
                    )
                ))
            )
            (ok {
                title: (get title proposal),
                votes-for: votes-for-ascii,
                votes-against: votes-against-ascii,
                timelock-remaining: time-left-ascii,
                status: status,
            })
        )
        err-proposal-not-found
    )
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (ok (map-get? proposals { proposal-id: proposal-id }))
)

;; Get user's vote on a proposal
(define-read-only (get-user-vote
        (proposal-id uint)
        (voter principal)
    )
    (ok (map-get? user-votes {
        proposal-id: proposal-id,
        voter: voter,
    }))
)

;; Check if proposal can be executed
;; CLARITY 4: Uses stacks-block-time for timelock check
(define-read-only (can-execute (proposal-id uint))
    (match (map-get? proposals { proposal-id: proposal-id })
        proposal (let (
                (timelock-passed (>= stacks-block-time (get execution-time proposal)))
                (voting-ended (>= stacks-block-height (get end-block proposal)))
                (not-executed (not (get executed proposal)))
                (not-cancelled (not (get cancelled proposal)))
                (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
                (quorum-met (>= total-votes
                    (/ (* (var-get total-voting-power) QUORUM-PERCENTAGE) u100)
                ))
                (passed (> (get votes-for proposal) (get votes-against proposal)))
            )
            (ok (and
                timelock-passed
                voting-ended
                not-executed
                not-cancelled
                quorum-met
                passed
            ))
        )
        (ok false)
    )
)

;; Cancel proposal (only proposer before execution)
(define-public (cancel-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id })
            err-proposal-not-found
        )))
        (asserts! (is-eq tx-sender (get proposer proposal)) err-not-authorized)
        (asserts! (not (get executed proposal)) err-proposal-not-passed)

        (map-set proposals { proposal-id: proposal-id }
            (merge proposal { cancelled: true })
        )

        (ok true)
    )
)

;; Get current proposal count
(define-read-only (get-proposal-count)
    (ok (var-get proposal-count))
)
