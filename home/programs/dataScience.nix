{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      # Jupyter
      jupyterlab         # next-gen Jupyter web IDE
      notebook           # classic Jupyter Notebook
      ipython            # enhanced interactive shell
      ipykernel          # IPython kernel for Jupyter
      ipywidgets         # interactive widgets for notebooks

      # Core numerics / data frames
      numpy              # n-dimensional arrays
      pandas             # data frames
      scipy              # scientific computing
      polars             # fast DataFrame library
      pyarrow            # Arrow / Parquet columnar data

      # Visualisation
      matplotlib         # 2D plotting
      seaborn            # statistical plotting on matplotlib
      plotly             # interactive plots
      bokeh              # interactive web visualisation

      # Machine learning / stats
      scikit-learn       # classical ML
      statsmodels        # statistical models / tests
      xgboost            # gradient boosting

      # IO / utilities
      openpyxl           # read/write Excel .xlsx
      requests           # HTTP client
      sympy              # symbolic math
      tqdm               # progress bars
    ]))
  ];
}
