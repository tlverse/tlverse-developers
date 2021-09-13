
# Ensuring Code Quality

_Jeremy Coyle_


## Documenting and Testing your Learner {#doctest}
TODO: generalize

If you want other people to be able to use your learner, you will need to
document and provide unit tests for it. The above template has example
documentation, written in the [roxygen](http://r-pkgs.had.co.nz/man.html)
format. Most importantly, you should describe what your learner does, reference
any external code it uses, and document any parameters and public methods
defined by it.

It's also important to [test](http://r-pkgs.had.co.nz/tests.html) your learner.
You should write unit tests to verify that your learner can train and predict on
new data, and, if applicable, generate a chained task. It might also be a good
idea to use the `risk` function in `sl3` to verify your learner's performance on
a sample dataset. That way, if you change your learner and performance drops,
you know something may have gone wrong.
