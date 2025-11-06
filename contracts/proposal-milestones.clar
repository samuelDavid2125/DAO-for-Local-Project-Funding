(define-constant err-not-found (err u500))
(define-constant err-unauthorized (err u501))
(define-constant err-already-approved (err u502))
(define-constant err-already-completed (err u503))
(define-constant err-invalid-amount (err u504))
(define-constant err-max-milestones (err u505))
(define-constant err-insufficient-approvals (err u506))

(define-map proposal-milestones
  { proposal-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    amount: uint,
    approval-threshold: uint,
    approvals: uint,
    completed: bool,
    completed-at: (optional uint)
  }
)

(define-map milestone-counters
  uint
  uint
)

(define-map milestone-approvals
  { proposal-id: uint, milestone-id: uint, approver: principal }
  { approved-at: uint }
)

(define-public (create-milestone 
  (proposal-id uint)
  (description (string-ascii 200))
  (amount uint)
  (approval-threshold uint))
  (let
    (
      (proposal (unwrap! (contract-call? .DAO-for-Local-Project-Funding get-proposal proposal-id) err-not-found))
      (milestone-count (default-to u0 (map-get? milestone-counters proposal-id)))
      (new-milestone-id (+ milestone-count u1))
    )
    (asserts! (is-eq tx-sender (get proposer proposal)) err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> approval-threshold u0) err-invalid-amount)
    (asserts! (<= milestone-count u10) err-max-milestones)
    (map-set proposal-milestones
      { proposal-id: proposal-id, milestone-id: new-milestone-id }
      {
        description: description,
        amount: amount,
        approval-threshold: approval-threshold,
        approvals: u0,
        completed: false,
        completed-at: none
      }
    )
    (map-set milestone-counters proposal-id new-milestone-id)
    (ok new-milestone-id)
  )
)

(define-public (approve-milestone (proposal-id uint) (milestone-id uint))
  (let
    (
      (milestone (unwrap! (map-get? proposal-milestones { proposal-id: proposal-id, milestone-id: milestone-id }) err-not-found))
      (member-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake tx-sender))
      (existing-approval (map-get? milestone-approvals { proposal-id: proposal-id, milestone-id: milestone-id, approver: tx-sender }))
    )
    (asserts! (> member-stake u0) err-unauthorized)
    (asserts! (is-none existing-approval) err-already-approved)
    (asserts! (not (get completed milestone)) err-already-completed)
    (map-set milestone-approvals
      { proposal-id: proposal-id, milestone-id: milestone-id, approver: tx-sender }
      { approved-at: stacks-block-height }
    )
    (map-set proposal-milestones
      { proposal-id: proposal-id, milestone-id: milestone-id }
      (merge milestone { approvals: (+ (get approvals milestone) u1) })
    )
    (ok true)
  )
)

(define-public (complete-milestone (proposal-id uint) (milestone-id uint))
  (let
    (
      (milestone (unwrap! (map-get? proposal-milestones { proposal-id: proposal-id, milestone-id: milestone-id }) err-not-found))
      (proposal (unwrap! (contract-call? .DAO-for-Local-Project-Funding get-proposal proposal-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get proposer proposal)) err-unauthorized)
    (asserts! (not (get completed milestone)) err-already-completed)
    (asserts! (>= (get approvals milestone) (get approval-threshold milestone)) err-insufficient-approvals)
    (map-set proposal-milestones
      { proposal-id: proposal-id, milestone-id: milestone-id }
      (merge milestone { completed: true, completed-at: (some stacks-block-height) })
    )
    (ok true)
  )
)

(define-read-only (get-milestone (proposal-id uint) (milestone-id uint))
  (map-get? proposal-milestones { proposal-id: proposal-id, milestone-id: milestone-id })
)

(define-read-only (get-milestone-count (proposal-id uint))
  (default-to u0 (map-get? milestone-counters proposal-id))
)

(define-read-only (has-approved-milestone (proposal-id uint) (milestone-id uint) (approver principal))
  (is-some (map-get? milestone-approvals { proposal-id: proposal-id, milestone-id: milestone-id, approver: approver }))
)
