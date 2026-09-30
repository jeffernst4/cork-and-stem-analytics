import sys
import pandas as pd

input_file, output_file = sys.argv[1], sys.argv[2]

df = pd.read_csv(input_file)
df.columns = (
    df.columns.str.lower()
    .str.replace(".", "", regex=False)
    .str.replace("(%)", "pct", regex=False)
    .str.strip()
    .str.replace(" ", "_", regex=False)
)
df.to_csv(output_file, index=False)

print(list(df.columns))
