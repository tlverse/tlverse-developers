---
output:
  pdf_document: default
  html_document: default
---

# Computation Graphs with `delayed`

_Jeremy Coyle_

## Intro
##  Architecture
##  Other

## Previous Documentation


R supports a range of options to parallelize computation. For an overview, see
the [HPC Task
View](https://CRAN.R-project.org/view=HighPerformanceComputing) on
CRAN. In general, these options work extremely well for problems that are
_embarassingly parallel_, in that they support procedures such as parallel
`lapply` calls and parallel `for` loops -- essentially `map` operations.
However, there is no easy way to parallelize _dependent_ tasks in R.

In contrast, the Python language has the excellent framework for exactly this
purpose -- [`dask`](http://dask.pydata.org/en/latest/). `dask` makes it easy to
build up a graph of interdependent tasks and then execute them in parallel in an
order that optimizes performance [@daskLibrary]. The present package seeks to
reproduce a subset of that functionality in R, specifically the
[`delayed`](http://dask.pydata.org/en/latest/delayed.html) module. To
parallelize across the tasks, we leverage the excellent
[`future`](https://github.com/HenrikBengtsson/future/) package [@futurePackage].

The power of the `delayed` framework is best appreciated when demonstrated by
example.

---

## Example

The two primary ways to generate `Delayed` objects in R are via the `delayed`
and `delayed_fun` functions.

`delayed` is used to delay expressions


```r
library(delayed)
# delay a simple expression
delayed_object <- delayed(3 + 4)
print(delayed_object)
[1] "delayed(3 + 4)"
# compute its result
delayed_object$compute()
[1] 7
```

...while `delayed_fun` wraps a function so that it returns `Delayed` results


```r
# delay a function
x2 <- function(x) {x * x}
delayed_x2 <- delayed_fun(x2)

# calling it returns a delayed call
delayed_object <- delayed_x2(4)
print(delayed_object)
[1] "delayed(x2(x = 4))"
# again, we can compute its result
delayed_object$compute()
[1] 16
```

These elements of the functionality of `delayed` are substantially similar to
the facilities already offered by the `future` package. `delayed` diverges from
`future` by offereing the ability to chain `Delayed` objects together. For
example:


```r
# delay a simple expression
delayed_object_7 <- delayed(3 + 4)

# and another
delayed_object_3 <- delayed(1 + 2)

# delay a function for addition
adder <- function(x, y){x + y}
delayed_adder <- delayed_fun(adder)

# but now, use one delayed as input to another
chained_delayed_10 <- delayed_adder(delayed_object_7, delayed_object_3)

# We can still compute its result.
chained_delayed_10$compute()
[1] 10
```

We can visualize the dependency structure of these delayed tasks by calling
`plot` on the resultant `Delayed` object:


```r
plot(chained_delayed_10)
```

```{=html}
<div id="htmlwidget-f24f61b14a52b30b1486" style="width:100%;height:500px;" class="visNetwork html-widget"></div>
<script type="application/json" data-for="htmlwidget-f24f61b14a52b30b1486">{"x":{"nodes":{"id":["64f37a52-1456-11ec-83e3-000d3aec34c9","64f2c2b0-1456-11ec-83e3-000d3aec34c9","64f2f99c-1456-11ec-83e3-000d3aec34c9"],"label":["adder(x = delayed_object_7, y = delayed_object_3)","3 + 4","1 + 2"],"level":[1,2,2],"sequential":[false,false,false],"state":["resolved","resolved","resolved"],"group":["resolved","resolved","resolved"],"shape":["dot","dot","dot"]},"edges":{"from":["64f2c2b0-1456-11ec-83e3-000d3aec34c9","64f2f99c-1456-11ec-83e3-000d3aec34c9"],"to":["64f37a52-1456-11ec-83e3-000d3aec34c9","64f37a52-1456-11ec-83e3-000d3aec34c9"],"label":["",""]},"nodesToDataframe":true,"edgesToDataframe":true,"options":{"width":"100%","height":"100%","nodes":{"shape":"dot"},"manipulation":{"enabled":false},"edges":{"arrows":"to"},"layout":{"hierarchical":{"enabled":true,"levelSeparation":500,"nodeSpacing":200,"direction":"RL"}},"groups":{"waiting":{"color":{"border":"black","background":"white"}},"ready":{"color":{"border":"black","background":"orange"}},"running":{"color":{"border":"black","background":"lightgreen"}},"resolved":{"color":{"border":"black","background":"black"}},"useDefaultGroups":true,"error":{"color":{"border":"black","background":"lightpink"}}}},"groups":["resolved"],"width":"100%","height":"500px","idselection":{"enabled":false},"byselection":{"enabled":false},"main":null,"submain":null,"footer":null,"background":"rgba(0, 0, 0, 0)","legend":{"width":0.2,"useGroups":false,"position":"left","ncol":1,"stepX":100,"stepY":100,"zoom":true,"nodes":{"label":["waiting","ready","running","resolved","error","sequential","parallel"],"color":[{"border":"black","background":"white"},{"border":"black","background":"orange"},{"border":"black","background":"lightgreen"},{"border":"black","background":"black"},{"border":"black","background":"lightpink"},{"border":"black","background":"white"},{"border":"black","background":"white"}],"shape":["dot","dot","dot","dot","dot","square","dot"]},"nodesToDataframe":true}},"evals":[],"jsHooks":[]}</script>
```

---

## Parallelization

Now that we've had an elementary look at the functionality offered by `delayed`,
we may take a look at how to parallelize dependent computations -- the core
problem addressed by the package. We can easily parallelize across dependency
structures by specifying a `future` `plan`. Let's try it out


```r
library(future)
plan(multicore, workers = 2)

# re-define the delayed object from above
delayed_object_7 <- delayed(3 + 4)
delayed_object_3 <- delayed(1 + 2)
chained_delayed_10 <- delayed_adder(delayed_object_7, delayed_object_3)

# compute it using the future plan (two multicore workers), verbose mode lets
# us see the computation order
chained_delayed_10$compute(nworkers = 2, verbose = TRUE)
[1] 10
```

The above illustrates the typical lifecycle of a delayed task. Such procedures
start with a state of `"waiting"`, which means that a given task depends on
other delayed tasks that are not yet complete. If the task in question has no
delayed dependencies -- or when these dependencies become resolved -- the task
transitions to a `"ready"` state. This means it will be run as soon as a worker
is available to process the task. Once the task is assigned to a worker, the
state of the task changes to `"running"`; and when processing of the task is
complete, it is finally marked `"resolved"`.

---

## Future Work

### Scheduling Tasks

When multiple tasks are simulatenously `"ready"`, the scheduler must decide
which to assign to the next available worker. Currently, the scheduler simply
prioritizes tasks that are likely to result in other tasks becoming "ready". In
the future, we plan to build more advanced scheduling features, similar to those
available in the `dask` library. An overview of that functionality is described
here: https://distributed.readthedocs.io/en/latest/scheduling-policies.html

### Distributed Data

Another key features of `dask` is [_data
locality_](https://distributed.readthedocs.io/en/latest/locality.html). That is,
data is only present on workers that need it for a given task, and is only
shared between workers when necessary. Tasks are then prioritized to workers
that have all the necessary components. We have begun to implement a similar
framework, though this work remains incomplete.
