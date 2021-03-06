;;; Genetic Algorithm to model short beak / long beak in finches in the Galapagos
;;; CSC 366 Final Project
;;; Authors: Emma Brunell, Tyler Dominick, Sean McGrath, Samson Manoah

;************************** Initial Statements ***********************************:

; number of finches 
(setf *finches* 15)

; randomly generate a length of finch beak
(defun finches ()
  (nth (random 8) '(1 2 3 4 5 6 7 8) )
)

; generate a list of finches 
(defun finch-list ((i integer))
  (cond
   ( (= 0 i) nil)
   (t
    (cons (finches) (finch-list (- i 1) ) )
   )
  )
)

; string representation of number of random finches
(defun finch-string ()
  (finch-list *finches*)
)

;************************* String Mutation **************************************:

; selects a random item from the list
(defun pick (lst)
  (select (random (length lst) ) lst)
)

; returns the element of the list in a given position
(defun select (i lst)
  (cond
   ( (null lst) nil)
   ( (equal i 0) (car lst) )
   (t
    (select (- i 1) (cdr lst) )
    )
  )
)

; mutate the string
(defmethod mutation ( (finch-string list) &aux p q)
  (setf p (random (length finch-string) ) )
  (setf q (others '(1 2 3 4 5 6 7 8) (nth p finch-string) ) )
  (change finch-string (pick q) p )
)

(defmethod others ((lst list) x)
  (remove x lst)
)

(defmethod change ((lst list) x (i integer))
  (setf (nth i lst) x)
  lst
)

;*************************** String Crossover **********************************:

; crossover the string
(defmethod crossover ((mother list) (father list) )
  (setf position (+ 1 (random (length mother) ) ) )
  (append (firstn mother position) (restn father position) )
)

(defmethod firstn ((m list) (p integer))
  (subseq m 0 p)
)

(defmethod restn ((f list) (p integer))
  (subseq f p)
)

;************************ Define Fitness Metrics ********************************:

(defmethod fitness-long ((lst list))
  (count-if (lambda (element) (> element 4) ) lst )
)

(defmethod fitness-short ((lst list))
  (count-if (lambda (element) (<= element 4) ) lst )
)


;************************ The Individual ********************************:

(defclass individual ()
  (
   (finch-string :accessor individual-finch-string :initarg :finch-string)
   (fitness :accessor individual-fitness :initarg :fitness)
   (number :accessor individual-number :initarg :number)
  )
)

(defmethod random-individual (&aux finch)
  (setf finch (finch-string) )
  (make-instance 'individual
		 :finch-string finch
		 :fitness (funcall *fitness* finch)
		 :number 0
  )
)

(defmethod new-individual ( (n number) (lst list) )
  (make-instance 'individual
		 :finch-string lst
		 :fitness (funcall *fitness* lst)
		 :number n
  )
)

(defmethod display ((i individual))
  (display-nnl i)(terpri)
)

(defmethod display-nnl ((i individual))
  (princ "Group #")
  (prin1 (individual-number i))
  (princ (filler (individual-number i)))
  (prin1 (individual-finch-string i))
  (princ "    ")
  (princ "Fitness: ")
  (prin1 (individual-fitness i))
  (princ (filler (individual-fitness i)))
)

(defmethod filler ((i integer))
  (cond
   ((< i 10) "       ")
   ((< i 100) "      ")
   ((< i 1000) "     ")
   ((< i 10000) "    ")
   ((< i 100000) "   ")
  )
)


(defmethod fitness-long ((i individual))
  (fitness-long (individual-finch-string i) )
)


(defmethod fitness-short ((i individual))
  (fitness-short (individual-finch-string i) )
)


;************************ The Population ********************************:

(defconstant *population-size* 10)
(defconstant *selection-size* 8)

(defclass population ()
  (
   (individuals :accessor population-individuals :initarg :individuals)
   (generation :accessor population-generation :initform 0)
  )
)

(defmethod size ((p population))
  (length (population-individuals p) )
)

(defmethod initial-population (&aux individuals)
  (setf individuals ())
  (dotimes (i *population-size*)
    (push (new-individual ( + i 1) (finch-string)) individuals)
   )
  (make-instance 'population :individuals (reverse individuals))
)
(defmethod average ((p population) &aux (sum 0))
  (dolist (i (population-individuals p))
    (setf sum (+ sum (funcall *fitness* i)))
  )
  (float (/ sum (size p)))
)

(defmethod individual-population (&aux individuals)
  (setf individuals () )
  (dotimes (i *population-size*)
    (push (new-individual (+ i 1) (finch-string) ) individuals )
  )
  (make-instance 'population :individuals (reverse individuals) )
)

(defmethod average ((p population) &aux (sum 0) )
  (dolist (i (population-individuals p) )
    (setf sum (+ sum (funcall *fitness* i) ) )
  )
  (float (/ sum (size p) ) )
)

(setf *select-demo* nil)

(defmethod select-individual ((p population) &aux i candidates rn)
  (setf candidates (select-individuals p) )
  (setf mfi (most-fit-individual candidates) )
  (if *select-demo* (select-demo-helper candidates mfi) )
  mfi
)

(defmethod select-individuals ((p population) &aux individuals candidates rn)
  (setf individuals (population-individuals p) )
  (setf candidates () )
  (dotimes (i *selection-size*)
    (setf rn (random *population-size*) )
    (push (nth rn individuals) candidates)
  )
  candidates
)

(defmethod most-fit-individual ((l list) &aux max-value max-individual)
  (setf max-individual () )
  (setf max-value 0)
  (dolist (i l)
    (if (> (funcall *fitness* i) max-value)
	(let ()
	  (setf max-value (funcall *fitness* i) )
	  (setf max-individual i)
	  )
      )
    )
  max-individual
)

(defmethod display ((p population))
  (princ "Generation ")
  (prin1 (population-generation p))
  (princ " population ...")
  (terpri)(terpri)
  (dolist (i (population-individuals p))
    (display i)
  )
  (terpri)
)

(defmethod select-demo-helper ((l list) (i individual) )
  (princ "The sample of individuals ...") (terpri)
  (mapcar #'display l)
  (terpri)
  (princ "The most fit of the sample ...") (terpri)
  (display i)
  (terpri)
  nil
)


;************************ Incorportate Mutation ********************************:

(defmethod mutate ((i individual) &aux mutation)
  (setf mutation (mutation (individual-finch-string i) ) )
  (make-instance 'individual
		 :number (individual-number i)
		 :finch-string mutation
		 :fitness (funcall *fitness* mutation)
  )
)

; the percent of new individuals that are mutated
(defconstant *pc-m* 50)

(defmethod maybe-mutate ((i individual))
  (if (<= (+ 1 (random 100) ) *pc-m*)
      (mutate i)
      i
  )
)

;********* Copy Individuals from Source Population --> Next Generation **********:

(setf *copy-demo* nil)

; percent copied
(defconstant *pc-c* 40)

(defmethod perform-copies ((cp population) (np population))
  (dotimes (i (nr-copies) )
    (perform-one-copy cp np)
  )
)

(defmethod nr-copies ()
  (* ( / *pc-c* 100) *population-size* )
)

(defmethod perform-one-copy ((cp population) (np population) &aux x m mm new-i)
  (setf m (select-individual cp) )
  (setf mm (maybe-mutate m) )
  (if *copy-demo* (format t "Possibly mutated individual = ~&"))
  (if *copy-demo* (display mm) )
  (setf (individual-number mm) (+ 1 (size np) )  )
  (if *copy-demo* (format t "Renumbered individual = ~&") )
  (if *copy-demo* (display mm) )
  (setf new-i (new-individual ( + 1 (size np) ) (individual-finch-string mm) ) )
  (setf
   (population-individuals np)
   (append (population-individuals np)(list new-i) )
   )
  nil
)

(defmethod empty-population ((cp population) &aux np)
  (setf np (make-instance 'population) )
  (setf (population-individuals np) () )
  (setf (population-generation np) (+ 1 (population-generation cp) ) )
  np
)

;************************ Perform Crossover ********************************:

(setf *crossover-demo* nil)

; percent crossover
(defconstant *pc-x* 60)

(defmethod perform-crossovers ((cp population) (np population))
  (dotimes (i (nr-crossovers) )
    (perform-one-crossover cp np)
  )
)
(defmethod nr-crossovers ()
	(* (/ *pc-x* 100) *population-size*)
)

(defmethod perform-one-crossover ((cp population) (np population))
  (let (x m mm mother father new-i)
    (setf mother (select-individual cp) )
    (setf father (select-individual cp) )
    (if *crossover-demo* (format t "Selected mother = ~%") )
    (if *crossover-demo* (display mother) )
    (if *crossover-demo* (format t "Selected father = ~&") )
    (if *crossover-demo* (display father) )
    (setf m (crossover mother father) )
    (if *crossover-demo* (format t "The crossover = ~&") )
    (if *crossover-demo* (display m) )
    (setf mm (maybe-mutate m) )
    (if *crossover-demo* (format t "The possibly mutated individual = ~&") )
    (if *crossover-demo* (display mm) )
    (setf (individual-number mm) (+ 1 (size np) ) )
    (if *crossover-demo* (format t "The renumbered individual = ~&") )
    (if *crossover-demo* (display mm) )
    (setf new-i (new-individual (+ 1 (size np) ) (individual-finch-string mm) ) )
    (setf (population-individuals np) (append (population-individuals np)
					      (list new-i) )
    )
  )
)

(defmethod crossover ((mother individual) (father individual) &aux mi fi x i)
  (setf mi (individual-finch-string mother) )
  (setf fi (individual-finch-string father) )
  (setf x (crossover mi fi) )
  (setf i (new-individual 0 x) )
  i
)


;************************ Perform the GA ********************************:

(defconstant *nr-generations* 25)

(defmethod next-generation ((cp population) &aux np)
  (setf np (empty-population cp))
  (perform-copies cp np)
  (perform-crossovers cp np)
  np
)

; The GA
(defmethod ga-text-demo (&aux p)
    (terpri)
    (write-line "        / \\ . _           ")
    (write-line "        \\` \\ / '-.      ")
    (write-line "      < ``-.(),--'`      ")
    (write-line "       '--.()()`--.      ")
    (write-line "        / |/-/`'._\\      ")
    (write-line "           |=|           ")
    (write-line "           |_|           ")
    (write-line "      ~`   |-| ~~      ~ ")
    (write-line "  ~~  ~~ __|=|__   ~~    ")
    (write-line "~~   .-'`  |_|  ````-._   ~~ ")
    (write-line " ~~.'      |=|         '-.  ~ ")
    (write-line "  |      `'`'`            \   ~ ")
    (write-line "~   \      FINCH ISLAND    | ~~ ")
    (write-line "  ~~  '-.__.--._         .-'    ")
    (write-line "    ~~      ~~   '--...-'`    ~~  ")
    (write-line "  ~~    ~~     ~   ~~       ~ ")
    (write-line "     ~~     ~    ~~     ~   ")


  (terpri) (terpri)
  (format t "THE ISLAND SELECTS FOR LONG BEAKS (Length = 5-8cm):~%~%")
  (write-line "     \\\\ " )
  (write-line "      (o=====> ")
  (write-line "  \\\\_//) ")
  (write-line "   \\_/_) ")
  (write-line "    _|_   ")
  (terpri)
  (setf *fitness* #'fitness-long)
  (setf p (initial-population) )
  (terpri)
  (summarize p)
  (dotimes (i *nr-generations*)
    (setf p (next-generation p) )
    (check-average p)
  )
  (terpri)
  (summarize p)
  (terpri)
  (format t "THE ISLAND SELECTS FOR SHORT BEAKS (Length = 1-4cm):~%~%")
  (write-line "     \\\\ " )
  (write-line "      (o> ")
  (write-line "  \\\\_//) ")
  (write-line "   \\_/_) ")
  (write-line "    _|_   ")
  (terpri)
  (setf *fitness* #'fitness-short)
  (dotimes (i *nr-generations*)
    (setf p (next-generation p) )
    (check-average p)
  )
  (terpri)
  (summarize p)
)

(defmethod summarize ((p population))
  (display p)
  (check-average p)
  (average p)
)

(defmethod check-average ((p population))
  (format t "avg fitness of finch population ~A = ~A~%" 
			(population-generation p) (average p) )
)
