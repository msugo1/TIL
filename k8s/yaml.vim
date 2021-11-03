#YAML

1. Key - Value Pair
```
Fruit: Apple
Vegetable: Carrot
...
```

2. Array/Lists
```
Fruits:
- Orange
- Apple

Vegetagles:
- Carrot
- Cauliflower
...
```

3. Dictionary/Map
```
Banana:
  Calories: 105
  Fat: 0.4g
  Carbs: 27g

Grapes:
  Calories: 62
  Fat: 0.3g
  Carbs: 16g
```

* indentation distinguishes the level or parent-child relations
= the same hierarchy requires identical spaces

* Dictionary = Unordered, List = Ordered

# JSON
- JSON has a different format but YAML and JSON are highly compatible especially with converters

# JSON_PATH
- a Query language
- gives you a result with JSON data

ex.
  car, car.colour


* root element
{
  "car": {
  
  }
}

this dictionay has a dictionay of "car", which is in another dictionary called, root element
- root element is denoted by $
  = $.car.colour ...

- the result of JSON query is wrapped in [ ] (array)


then how to query an element from an array?
[
  "car",
  "bus"
  ...
]

= $[0] = car, $[1] = bus
it works with indices!

$[0, 3] 
= elements at the 0 and 3 indices

$.
= dot means a dictionary

[ 12, 43, 23, .. ]

$[?( @ > 40 )]

- ?: if
- @: each item in the list

ex. @ == 40, @ != 40, @ in [40, 43, 45], @ nin [40, 43, 45]

* $.car.wheels[2].model
- an element located at the exact index can always be replaced by another element if the order is messed up
  (once it was A might not be the same A next time)

- then, why don't we get it by specifying the name?
  = $car.wheels[?(@.location == "rear-right")].model

# Wild Card in JSON Path
= as expected, `*`

ex. $.car.wheels[*].model
$.*.wheels[*].model
$.prizes[?(@.year ==2014)].laureates[*].firstname

# List
* search throughout a specific range
$[0:3] 
= $[start:end]

$[0:8:2]
= $[start:end:step]

index -1 means the last index
  However, $[-1] doesn't work for all implementations out there
  Therefore, $[-1:0]

# JSON PATH in k8s with `kubectl`
1. Why JSON Path?
  - Large Data sets in production
  ex. 100s of Nodes, 1000s of Pods, Deployments, ReplicaSets
  - JSON Path allows you to filter data across large data sets with ease

2. How to JSON PATH in KubeCtl?
  - kubectl get pod -o json (output as a json)
    then form the JSON PATH query
    (ex. .items[0].spec.containers[0].image - $ won't be necessary, kubectl adds it automatically)

  - in turn,
  `kubectl get pods -o=jsonpath={ .items[0].spec.containers[0].image }
   (do not forget the curly braces!)

  - multiple JSON PATH queries can be used together
  `kubectl get nodes -o=jsonpath='{.items[*].metadata.name}{.items[*].status.capacity.cpu}`

3. prettifying, and formatting
  ex. add a new line char between two queries
  '{.items[*].metadata.name}{"\n"}{.items[*].status.capacity.cpu}`

  {"\t"} = tab

4. Loops - Range

ex.
FOR EACH NODE
  PRINT NODE \t PRINT CPU COUNT \n
END FOR

=

FOR EACH = range
'{range .items[*]}' 
  {.metadata.name} {"\t"} {status.capacity.cpu} {"\n"}
{end}'

in a single line though!

or =

`kubectl get nodes -o=custom-columns=<COLUMN NAME>:<JSON PATH>`

ex.
  kubectl get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu

# JSON PATH for SORT
`kubectl get nodes --sort-by=`
ex. 
  kubectl get nodes --sort-by={ .status.capacity.cpu }



