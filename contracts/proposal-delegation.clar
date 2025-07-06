(define-constant err-self-delegation (err u200))
(define-constant err-not-member (err u201))
(define-constant err-no-delegation (err u202))
(define-constant err-circular-delegation (err u203))

(define-map delegations
  principal
  { delegate: principal, delegated-block: uint }
)

(define-map delegate-power
  principal
  { total-power: uint, delegator-count: uint }
)


(define-public (delegate-voting-power (delegate principal))
  (let
    (
      (delegator tx-sender)
      (delegator-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake delegator))
      (delegate-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake delegate))
      (existing-delegation (map-get? delegations delegator))
    )
    (asserts! (> delegator-stake u0) err-not-member)
    (asserts! (> delegate-stake u0) err-not-member)
    (asserts! (not (is-eq delegator delegate)) err-self-delegation)
    (asserts! (not (is-some (map-get? delegations delegate))) err-circular-delegation)
    (match existing-delegation
      old-delegation (update-delegate-power (get delegate old-delegation) false delegator-stake)
      true
    )
    (map-set delegations delegator { delegate: delegate, delegated-block: stacks-block-height })
    (update-delegate-power delegate true delegator-stake)
    (ok true)
  )
)

(define-public (undelegate-voting-power)
  (let
    (
      (delegator tx-sender)
      (delegator-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake delegator))
      (delegation (unwrap! (map-get? delegations delegator) err-no-delegation))
    )
    (map-delete delegations delegator)
    (update-delegate-power (get delegate delegation) false delegator-stake)
    (ok true)
  )
)

(define-private (update-delegate-power (delegate principal) (is-adding bool) (stake uint))
  (let
    (
      (current-power (default-to { total-power: u0, delegator-count: u0 } 
                                 (map-get? delegate-power delegate)))
      (new-power (if is-adding (+ (get total-power current-power) stake) 
                               (- (get total-power current-power) stake)))
      (new-count (if is-adding (+ (get delegator-count current-power) u1) 
                               (- (get delegator-count current-power) u1)))
    )
    (if (and (is-eq new-power u0) (is-eq new-count u0))
      (map-delete delegate-power delegate)
      (map-set delegate-power delegate { total-power: new-power, delegator-count: new-count })
    )
    true
  )
)

(define-read-only (get-delegation (delegator principal))
  (map-get? delegations delegator)
)

(define-read-only (get-delegate-power (delegate principal))
  (default-to { total-power: u0, delegator-count: u0 } 
              (map-get? delegate-power delegate))
)

(define-read-only (get-total-voting-power (member principal))
  (let
    (
      (own-stake (contract-call? .DAO-for-Local-Project-Funding get-member-stake member))
      (delegated-power (get total-power (get-delegate-power member)))
    )
    (+ own-stake delegated-power)
  )
)

(define-read-only (is-delegated (member principal))
  (is-some (map-get? delegations member))
)
