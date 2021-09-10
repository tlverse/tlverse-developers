# Cross-validation with `origami`

_Jeremy Coyle_

## Intro
## Architecture
## Other

## Previous Documentation


## General workflow

Generally, `cross_validate` usage will mirror the workflow in the above example.
First, the user must define folds and a function that operates on each fold.
Once these are passed to `cross_validate`, the function will map the function
across the folds, and combine the results in a reasonable way. More details on
each step of this process will be given below.

### Define folds

The `folds` object passed to `cross_validate` is a list of folds. Such lists can
be generated using the `make_folds` function. Each `fold` consists of a list
with a `training` index vector, a `validation` index vector, and a `fold_index`
(its order in the list of folds). This function supports a variety of
cross-validation schemes including _v-fold_ and _bootstrap_ cross-validation as
well as time series methods like _"Rolling Window"_. It can balance across levels of a
variable (`stratify_ids`), and it can also keep all observations from the same
independent unit together (`cluster_ids`). See the documentation of the `make_folds`
function for details about supported cross-validation schemes and arguments.

### Define fold function

The `cv_fun` argument to `cross_validate` is a function that will perform some
operation on each fold. The first argument to this function must be `fold`,
which will receive an individual fold object to operate on. Additional arguments
can be passed to `cv_fun` using the `...` argument to `cross_validate`. Within
this function, the convenience functions `training`, `validation` and
`fold_index` can return the various components of a fold object. They do this by
retrieving the `fold` object from their calling environment. It can also be
specified directly. If `training` or `validation` is passed an object, it will
index into it in a sensible way. For instance, if it is a vector, it will index
the vector directly. If it is a `data.frame` or `matrix`, it will index rows.
This allows the user to easily partition data into training and validation sets.
This fold function must return a named list of results containing whatever
fold-specific outputs are generated.

### Apply `cross_validate`

After defining folds, `cross_validate` can be used to map the `cv_fun` across
the `folds` using `future_lapply`. This means that it can be easily parallelized
by specifying a parallelization scheme (i.e., a `plan`). See the [`future`
package](https://github.com/HenrikBengtsson/future) for more details.

The application of `cross_validate` generates a list of results. As described
above, each call to `cv_fun` itself returns a list of results, with different
elements for each type of result we care about. The main loop generates a list
of these individual lists of results (a sort of "meta-list"). This "meta-list"
is then inverted such that there is one element per result type (this too is a
list of the results for each fold). By default, `combine_results` is used to
combine these results type lists.

For instance, in the above `mtcars` example, the results type lists contains one
`coef` `data.frame` from each fold. These are `rbind`ed together to form one
`data.frame` containing the `coefs` from all folds in different rows. How
results are combined is determined automatically by examining the data types
of the results from the first fold. This can be modified by specifying a list of
arguments to `.combine_control`. See the help for `combine_results` for more
details. In most cases, the defaults should suffice.
