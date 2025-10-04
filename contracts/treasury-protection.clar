(define-constant err-unauthorized (err u400))
(define-constant err-invalid-amount (err u401))
(define-constant err-withdrawal-exists (err u402))
(define-constant err-withdrawal-not-found (err u403))
(define-constant err-withdrawal-active (err u404))
(define-constant err-insufficient-balance (err u405))

(define-data-var withdrawal-counter uint u0)
(define-data-var daily-withdrawal-limit uint u1000000)
(define-data-var emergency-timelock uint u144)

(define-map emergency-withdrawals
  uint
  {
    requester: principal,
    amount: uint,
    reason: (string-ascii 200),
    request-block: uint,
    execution-block: uint,
    executed: bool,
    cancelled: bool
  }
)

(define-map daily-withdrawals
  { date: uint, member: principal }
  uint
)

(define-public (request-emergency-withdrawal (amount uint) (reason (string-ascii 200)))
  (let
    (
      (requester tx-sender)
      (withdrawal-id (+ (var-get withdrawal-counter) u1))
      (member-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake requester))
      (treasury-balance (get treasury-balance (contract-call? .DAO-for-Local-Project-Funding get-dao-stats)))
    )
    (asserts! (> member-stake u0) err-unauthorized)
    (asserts! (and (> amount u0) (<= amount treasury-balance)) err-invalid-amount)
    (map-set emergency-withdrawals withdrawal-id
      {
        requester: requester,
        amount: amount,
        reason: reason,
        request-block: stacks-block-height,
        execution-block: (+ stacks-block-height (var-get emergency-timelock)),
        executed: false,
        cancelled: false
      }
    )
    (var-set withdrawal-counter withdrawal-id)
    (ok withdrawal-id)
  )
)

(define-public (execute-emergency-withdrawal (withdrawal-id uint))
  (let
    (
      (withdrawal (unwrap! (map-get? emergency-withdrawals withdrawal-id) err-withdrawal-not-found))
      (treasury-balance (get treasury-balance (contract-call? .DAO-for-Local-Project-Funding get-dao-stats)))
    )
    (asserts! (is-eq tx-sender (get requester withdrawal)) err-unauthorized)
    (asserts! (>= stacks-block-height (get execution-block withdrawal)) err-withdrawal-active)
    (asserts! (not (get executed withdrawal)) err-withdrawal-exists)
    (asserts! (not (get cancelled withdrawal)) err-withdrawal-exists)
    (asserts! (>= treasury-balance (get amount withdrawal)) err-insufficient-balance)
    (map-set emergency-withdrawals withdrawal-id
      (merge withdrawal { executed: true })
    )
    (ok true)
  )
)

(define-public (cancel-emergency-withdrawal (withdrawal-id uint))
  (let
    (
      (withdrawal (unwrap! (map-get? emergency-withdrawals withdrawal-id) err-withdrawal-not-found))
    )
    (asserts! (is-eq tx-sender (get requester withdrawal)) err-unauthorized)
    (asserts! (not (get executed withdrawal)) err-withdrawal-exists)
    (asserts! (not (get cancelled withdrawal)) err-withdrawal-exists)
    (map-set emergency-withdrawals withdrawal-id
      (merge withdrawal { cancelled: true })
    )
    (ok true)
  )
)

(define-read-only (get-emergency-withdrawal (withdrawal-id uint))
  (map-get? emergency-withdrawals withdrawal-id)
)

(define-read-only (get-daily-withdrawal (member principal))
  (let
    (
      (today (/ stacks-block-height u144))
    )
    (default-to u0 (map-get? daily-withdrawals { date: today, member: member }))
  )
)

(define-read-only (can-execute-withdrawal (withdrawal-id uint))
  (match (map-get? emergency-withdrawals withdrawal-id)
    withdrawal (and
      (>= stacks-block-height (get execution-block withdrawal))
      (not (get executed withdrawal))
      (not (get cancelled withdrawal))
    )
    false
  )
)

(define-read-only (get-protection-settings)
  {
    daily-limit: (var-get daily-withdrawal-limit),
    timelock-blocks: (var-get emergency-timelock),
    total-requests: (var-get withdrawal-counter)
  }
)
