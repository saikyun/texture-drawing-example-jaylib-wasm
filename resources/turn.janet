(import jaylib :as j)
(import ./params :as p)

(def rot-info
  [[[0 0] [3 0] [3 3] [0 3]]
   [[1 0] [3 1] [2 3] [0 2]]
   [[2 0] [3 2] [1 3] [0 1]]
   [[1 1] [2 1] [2 2] [1 2]]])

(defn can-rotate?
  [state]
  (def grid (state :grid))
  (defn blocked?
    [src dst]
    (and (= :moving (get-in grid src))
         (not= :empty (get-in grid dst))
         (not= :moving (get-in grid dst))))
  #
  (def piece-pos-x (state :piece-pos-x))
  (def piece-pos-y (state :piece-pos-y))
  #
  (var blocked false)
  (loop [row :in rot-info
         i :range [0 (length row)]
         :let [[x1 y1] (get row i)
               [x2 y2] (if (not= i (dec (length row)))
                         (get row (inc i))
                         (get row 0))]]
    (when (blocked? [(+ piece-pos-x x2) (+ piece-pos-y y2)]
                    [(+ piece-pos-x x1) (+ piece-pos-y y1)])
      (set blocked true)
      (break)))
  (put state :result (not blocked))
  #
  state)

(defn rotate-ccw!
  [state]
  (defn left-rotate-units
    [positions]
    (var aux
      (get-in state [:piece ;(first positions)]))
    (loop [i :range [0 (dec (length positions))]]
      (put-in state [:piece ;(get positions i)]
              (get-in state [:piece ;(get positions (inc i))])))
    (put-in state [:piece ;(last positions)] aux))
  #
  (each row rot-info
    (left-rotate-units row))
  #
  state)

(defn resolve-turn-move!
  [state]
  (var result false)
  (def grid (state :grid))
  #
  (when (j/key-down? :w)
    # rotate piece counterclockwise if appropriate
    (when ((can-rotate? state) :result)
      (rotate-ccw! state))
    # clear grid spots occupied that were occupied by piece
    (loop [j :down-to [(- p/grid-y-size 2) 0]
           i :range [1 (dec p/grid-x-size)]
           :when (= :moving
                    (get-in grid [i j]))]
      (put-in grid [i j] :empty))
    # fill grid spots that the piece occupies
    (def piece-pos-x (state :piece-pos-x))
    (def piece-pos-y (state :piece-pos-y))
    (loop [i :range [piece-pos-x (+ piece-pos-x 4)]
           j :range [piece-pos-y (+ piece-pos-y 4)]
           :when (= :moving
                    (get-in state
                            [:piece (- i piece-pos-x) (- j piece-pos-y)]))]
      (put-in grid [i j] :moving))
    #
    (set result true))
  #
  (put state :result result)
  #
  state)

