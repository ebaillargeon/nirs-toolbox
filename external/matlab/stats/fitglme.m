function glme = fitglme(T,formula,varargin)
%FITGLME Create a generalized linear mixed effects model by fitting to data
%   GLME = FITGLME(T,FORMULA) fits a generalized linear mixed effects
%   (GLME) model specified by the formula string FORMULA to variables in
%   the table array T using a normal distribution and the identity link, 
%   and returns the fitted model GLME. You can specify other distributions
%   and link functions using name-value pair arguments (described below).
%
%   To illustrate the formula syntax, suppose T contains a response
%   variable named y, predictor variables named x1, x2,..., xn (continuous
%   or grouping) and grouping variables named g1, g2,..., gR where the
%   grouping variables xi or gi can be categorical, logical, char arrays,
%   or cell arrays of strings. The formula string FORMULA specifies the
%   GLME model as follows:
%
%       'y ~ FIXED + (RANDOM_1 | Grp_1) + ... + (RANDOM_R | Grp_R)'
%   where
%       FIXED = a specification of the fixed effects design matrix
%       Grp_j = a single grouping variable (e.g., g2) or a multiway
%               interaction between grouping variables (e.g., g1:g2:g3)
%    RANDOM_j = a specification of the random effects design matrix 
%               corresponding to grouping variable Grp_j
%
%   The symbol '~' is interpreted as "modeled as" and the symbol '|' is
%   interpreted as "by". The specified GLME model contains one fixed effect
%   vector for the design matrix generated by FIXED. Rows of the design
%   matrix generated by RANDOM_j get multiplied by a separate random effect
%   vector for every level of grouping variable Grp_j. Random effect
%   vectors induced by (RANDOM_j | Grp_j) are drawn independently from a
%   prior Normal distribution with mean 0 and covariance matrix PSI_j.
%   Random effects for (RANDOM_i | Grp_i) and (RANDOM_j | Grp_j) are
%   independent of each other.
%   
%   The expressions FIXED and RANDOM_j contain "terms" which are either the
%   symbols x1,...,xn and g1,...,gR (defined as variables in the table T)
%   or their combinations joined by '+' and '-' (e.g., x1 + x2 + x3*x4).
%   Here are the rules for combining terms:
%
%           A + B       term A and term B
%           A - B       term A but without term B
%           A:B         the product of A and B
%           A*B         A + B + A:B
%           A^2         A + A:A
%           ()          grouping of terms
% 
%   The symbol '1' (one) stands for a column of all ones. By default, a
%   column of ones is always included in the design matrix. To exclude a
%   column of ones from the design matrix, explicitly specify '-1' as a
%   term in the expression. 
%
%   The following are some examples of FORMULA term expressions when the
%   predictors are x1, x2 response is y and grouping variables are g1, g2
%   and g3. We will denote an 'Intercept' by the symbol '1' in the examples
%   below.
%
%       'y ~ x1 + x2'         Fixed effects only for 1, x1 and x2.
%
%       'y ~ 1 + x1 + x2'     Fixed effects only for 1, x1 and x2. This
%                             time the presence of intercept is indicated 
%                             explicitly by listing '1' as a predictor in 
%                             the formula.
%
%       'y ~ -1 + x1 + x2'    Fixed effects only for x1 and x2. The
%                             implicit intercept term is suppressed by 
%                             including '-1' in the formula.
%
%       'y ~ 1 + (1 | g1)'    Intercept plus random effect for each level
%                             of the grouping variable g1.
%
%       'y ~ x1 + (1 | g1)'   Random intercept model with a fixed slope
%                             multiplying x1.
%
%       'y ~ x1 + (x1 | g1)'  Random intercepts and slopes, with possible
%                             correlation between them.
%
%       'y ~ x1 + (1 | g1) + (-1 + x1 | g1)' 
%                             Independent random intercepts and slopes.
%
%       'y ~ 1 + (1 | g1) + (1 | g2) + (1 | g1:g2)' 
%                             Random intercept model with independent main
%                             effects for g1 and g2, plus an independent
%                             interaction effect.
%
%   Suppose X is the fixed effects design matrix (specified by FIXED) and
%   beta is the corresponding fixed effects vector. Also, let Z be the
%   overall random effects design matrix (specified by (RANDOM_i | Grp_i))
%   and b be the corresponding combined random effects vector containing
%   all concatenated random effects from the GLME model. The conditional
%   mean mu of response y is modelled as:
%
%                   g(mu) = X*beta + Z*b + offset
%
%   where g is the link function (specified via 'Link' name/value pair).
%   The vector offset is optional and can be specified using the 'Offset'
%   name/value pair. Given b, response y is modeled as coming from one of
%   the supported distributions (specified using the 'Distribution'
%   name/value pair). The GLME model implicitly assumes that elements of y
%   are conditionally independent given b.
%
%   GLME = FITGLME(T,FORMULA,PARAM1,VAL1,PARAM2,VAL2,...) specifies one or
%   more of the following name/value pairs:
%       
%      'Distribution'     Name of the distribution for modelling the
%                         conditional distribution of the response, chosen
%                         from the following:
%                 'normal'             Normal distribution (default)
%                 'binomial'           Binomial distribution
%                 'poisson'            Poisson distribution
%                 'gamma'              Gamma distribution
%                 'inverse gaussian'   Inverse Gaussian distribution
%
%      'BinomialSize'     Vector or name of a variable of the same length
%                         as the response, specifying the size of the
%                         sample (number of trials) used in computing y.
%                         This is accepted only when the 'Distribution'
%                         parameter is 'binomial'. May be a scalar if all
%                         observations have the same value. Default is 1.
%
%      'Link'             The link function g to use in place of the
%                         canonical link. Specify the link as:
%                 'identity'    g(mu) = mu
%                 'log'         g(mu) = log(mu)
%                 'logit'       g(mu) = log(mu/(1-mu))
%                 'probit'      g(mu) = norminv(mu)
%                 'comploglog'  g(mu) = log(-log(1-mu))
%                 'loglog'      g(mu) = log(-log(mu))
%                 'reciprocal'  g(mu) = mu.^(-1)
%                 P (number)    g(mu) = mu.^P
%                 S (struct)    structure with four fields whose values
%                               are function handles with the following 
%                               names:
%                                  S.Link               link function
%                                  S.Derivative         derivative
%                                  S.SecondDerivative   second derivative
%                                  S.Inverse            inverse of link
%                         Specification of S.SecondDerivative can be
%                         omitted if 'FitMethod' is 'MPL' or 'REMPL' or if
%                         S represents a canonical link for the specified
%                         'Distribution'. The default is the canonical link
%                         that depends on the distribution:
%                 'identity'    normal distribution
%                 'logit'       binomial distribution
%                 'log'         Poisson distribution
%                 -1            gamma distribution
%                 -2            inverse gaussian distribution
%
%      'Offset'           Vector or name of a variable with the same
%                         length as the response. This is used as an
%                         additional predictor with a coefficient value
%                         fixed at 1.0. Default is zeros(N,1) where N is
%                         the number of rows in T.
%
%      'DispersionFlag'   Either true or false. Applies if 'FitMethod' is 
%                         'MPL' or 'REMPL'. If false, the dispersion
%                         parameter is fixed at its theoretical value of
%                         1.0 for binomial and Poisson distributions. If
%                         true, the dispersion parameter is estimated from
%                         data even for binomial and Poisson distributions.
%                         For all other distributions, the dispersion
%                         parameter is always estimated from data. 
%                         If 'FitMethod' is 'ApproximateLaplace' or 
%                         'Laplace', the dispersion parameter is
%                         always fixed at 1.0 for binomial and Poisson
%                         distributions and estimated from data for all
%                         other distributions. Default is false.
%
%      'CovariancePattern'   
%                         A cell array of length R such that element j of
%                         this cell array specifies the pattern of the
%                         covariance matrix of random effect vectors
%                         introduced by (RANDOM_j | Grp_j). Each element of
%                         the cell array for 'CovariancePattern' can either
%                         be a string or a logical matrix. Allowed values
%                         for element j are:
%          'FullCholesky'   - a full covariance matrix using the Cholesky 
%                             parameterization. All elements of the
%                             covariance matrix are estimated.
%          'Full'           - a full covariance matrix using the 
%                             log-Cholesky parameterization. All elements
%                             of the covariance matrix are estimated.
%          'Diagonal'       - a diagonal covariance matrix. Off-diagonal 
%                             elements of the covariance matrix are
%                             constrained to be 0.
%          'Isotropic'      - a diagonal covariance matrix with equal 
%                             variances. Off-diagonal elements are 
%                             constrained to be 0 and diagonal elements are 
%                             constrained to be equal.
%          'CompSymm'       - a matrix with compound symmetry structure 
%                             i.e., common variance along diagonals and 
%                             equal correlation between all elements of the
%                             random effect vector.
%           PAT             - A square symmetric logical matrix. If 
%                             PAT(a,b) = false then the (a,b) element of
%                             the covariance matrix is constrained to 0.
%                         Default is 'Isotropic' for scalar random effect
%                         terms such as (1 | g1) and 'FullCholesky'
%                         otherwise.
%
%       'FitMethod'       Specifies the method to use for estimating
%                         generalized linear mixed effects model
%                         parameters. Choices are:
%           'MPL'                 - maximum pseudo likelihood (Default)
%           'REMPL'               - restricted maximum pseudo likelihood
%           'ApproximateLaplace'  - maximum likelihood using approximate
%                                   Laplace approximation with fixed 
%                                   effects profiled out
%           'Laplace'             - maximum likelihood using Laplace 
%                                   approximation
%
%       'Weights'         Vector of N non-negative weights, where N is the
%                         number of rows in T. Default is ones(N,1). For
%                         binomial and Poisson distributions, 'Weights'
%                         must be a vector of positive integers.
%
%       'Exclude'         Vector of integer or logical indices into the 
%                         rows of T that should be excluded from the fit.
%                         Default is to use all rows.
%
%       'DummyVarCoding'  A string specifying the coding to use for dummy
%                         variables created from categorical variables.
%                         Valid coding schemes are 'reference' (coefficient
%                         for first category set to zero), 'effects'
%                         (coefficients sum to zero) and 'full' (one dummy
%                         variable for each category). Default is
%                         'reference'.
%
%       'Optimizer'       A string specifying the algorithm to use for
%                         optimization. Valid values of this parameter are
%                         'fminsearch', 'quasinewton' and 'fminunc'.
%                         'fminsearch' uses the derivative free Nelder-Mead
%                         method, 'quasinewton' uses a trust region based
%                         quasi-Newton method and 'fminunc' uses a line
%                         search based quasi-Newton method. Setting
%                         'Optimizer' to 'fminunc' requires the
%                         Optimization Toolbox. Default is 'quasinewton'.                        
%
%       'OptimizerOptions'
%                         If 'Optimizer' is 'fminsearch', then
%                         'OptimizerOptions' is a structure created by
%                         optimset('fminsearch'). See the documentation for
%                         optimset for a list of options supported by
%                         'fminsearch'.
%                         If 'Optimizer' is 'quasinewton', then
%                         'OptimizerOptions' is a structure created by
%                         statset('fitglme'). The quasi-Newton optimizer
%                         uses the following fields:
%           'TolFun'        - Relative tolerance on the gradient of the 
%                             objective function. Default is 1e-6.                  
%           'TolX'          - Absolute tolerance on the step size.
%                             Default is 1e-12.
%           'MaxIter'       - Maximum number of iterations allowed. 
%                             Default is 10000.
%           'Display'       - Level of display.  'off', 'iter', or 'final'.
%                             Default is off.
%                         If 'Optimizer' is 'fminunc', then 
%                         'OptimizerOptions' is an object set up using 
%                         optimoptions('fminunc'). See the documentation
%                         for optimoptions for a list of all the options
%                         supported by fminunc.
%                         If 'OptimizerOptions' is not supplied and
%                         'Optimizer' is 'fminsearch' then the default
%                         options created by optimset('fminsearch') are
%                         used. If 'OptimizerOptions' is not supplied and
%                         'Optimizer' is 'quasinewton' then the default
%                         options created by statset('fitglme') are used.
%                         If 'OptimizerOptions' is not supplied and
%                         'Optimizer' is 'fminunc' then the default options
%                         created by optimoptions('fminunc') are used with
%                         the 'Algorithm' set to 'quasi-newton'.
%
%       'StartMethod'     Method to use to start iterative optimization.
%                         Choices are 'default' (Default) and 'random'. If
%                         'StartMethod' is 'random', a random initial value
%                         is used to start iterative optimization,
%                         otherwise an internally defined default value is
%                         used.
%
%       'Verbose'         An integer between 0 and 2 indicating the 
%                         verbosity level. If 1 or 2 then progress of the
%                         iterative model fitting process is displayed on
%                         screen. Verbosity level 2 results in the display
%                         of iterative optimization information from the
%                         individual pseudo likelihood iterations and
%                         verbosity level 1 suppresses this display.
%                         The setting for 'Verbose' overrides field
%                         'Display' in 'OptimizerOptions'. Default is 0.
%
%       'CheckHessian'    Either true or false. If 'CheckHessian' is true
%                         then optimality of the solution is verified by
%                         performing positive definiteness checks on the
%                         Hessian of the objective function with respect to
%                         unconstrained parameters at convergence. Hessian
%                         checks are also performed to determine if the
%                         model is overparameterized in the number of
%                         covariance parameters. Default is false.
% 
%       'PLIterations'    A positive integer specifying the maximum number 
%                         of pseudo likelihood (PL) iterations. Default is
%                         100. PL is used for fitting the model if
%                         FitMethod is 'MPL' or 'REMPL'. For other
%                         FitMethod values, PL iterations are used to
%                         initialize parameters for subsequent
%                         optimization.
% 
%       'PLTolerance'     A real scalar to be used as a relative tolerance 
%                         factor on the linear predictor during PL
%                         iterations. Default is 1e-8.
% 
%       'MuStart'         A vector of size N-by-1 providing a starting 
%                         value for the conditional mean of y given b to
%                         initialize PL iterations. Legal values of
%                         elements in 'MuStart' are as follows:
%
%           Distribution          Legal values
%           'normal'              (-Inf,Inf)
%           'binomial'            (0,1)
%           'poisson'             (0,Inf)
%           'gamma'               (0,Inf)
%           'inverse gaussian'    (0,Inf)
% 
%       'InitPLIterations'
%                         Initial number of PL iterations used to
%                         initialize parameters for maximum likelihood (ML)
%                         based methods such as 'ApproximateLaplace' and
%                         'Laplace'. Default is 10. Must be greater than or
%                         equal to 1.
% 
%       'EBMethod'        Method used to approximate the empirical Bayes 
%                         (EB) estimates of the random effects. Choices are
%                         'Auto' (default), 'LineSearchNewton',
%                         'TrustRegion2D' and 'fsolve'. Using 'fsolve'
%                         requires the Optimization Toolbox. 'Auto'
%                         represents an automatically chosen 'EBMethod'
%                         suitable for the selected 'FitMethod'. 'Auto' and
%                         'LineSearchNewton' may fail for non-canonical
%                         link functions. In these cases, 'TrustRegion2D'
%                         or 'fsolve' are recommended.
% 
%       'EBOptions'       A structure containing options for EB 
%                         optimization. The following options are used:
% 
%                  'TolFun'      Relative tolerance on the gradient norm.
%                                Default is 1e-6.
%                  'TolX'        Absolute tolerance on the step size.
%                                Default is 1e-8.
%                  'MaxIter'     Maximum number of iterations. Default is
%                                100.
%                  'Display'     'off', 'iter' or 'final'. Default is 'off'.
% 
%                         For 'EBMethod' equal to 'Auto' and 'FitMethod'
%                         equal to 'Laplace', 'TolFun' is the relative
%                         tolerance on the linear predictor of the model
%                         and the option 'Display' does not apply. If
%                         'EBMethod' is 'fsolve', this must be an object
%                         created by optimoptions('fsolve').
% 
%       'CovarianceMethod'
%                         Method used to compute the covariance of 
%                         estimated parameters. Choices are 'Conditional'
%                         (default) and 'JointHessian. The 'Conditional'
%                         method computes a fast approximation to the
%                         covariance of fixed effects given the estimated
%                         covariance parameters. The 'Conditional' method
%                         does not compute the covariance of covariance
%                         parameters. The 'JointHessian' method computes
%                         the joint covariance of fixed effects and
%                         covariance parameters via the observed
%                         information matrix using the Laplacian log
%                         likelihood.
%
%       'UseSequentialFitting'    
%                         Either true or false. If false, all ML methods
%                         are initialized using 1 or more PL iterations. If
%                         true, the initial values from PL iterations are
%                         refined with 'ApproximateLaplace' for 'Laplace'
%                         based fitting. Default is false.
%
%   Example: Model gas mileage as a function of car weight, with a random
%            effect due to model year using a Normal distribution.
%      load carsmall
%      T = table(MPG,Weight,Model_Year);
%      glme = fitglme(T,'MPG ~ Weight + (1|Model_Year)','Distribution','Normal')
%
%   See also GeneralizedLinearMixedModel, LinearMixedModel.

%   Copyright 2013-2014 The MathWorks, Inc.

    narginchk(2,Inf);    
    glme = GeneralizedLinearMixedModel.fit(T,formula,varargin{:});
    
end % end of fitglme.