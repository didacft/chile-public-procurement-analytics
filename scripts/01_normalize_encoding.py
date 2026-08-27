from pathlib import Path
import csv

source = Path("data/raw/health/2025_H1/07OCTratoDirecto.csv")
target = Path("data/processed/health/2025_H1/07OCTratoDirecto_utf8.csv")

target.parent.mkdir(parents=True, exist_ok=True)

bad_pattern = "CONEXI\u00C3?N HEX\u00C3\uFFFDGONO"
good_pattern = "CONEXI\u00D3N HEX\u00C1GONO"

invalid_chars = 0
corrections = 0
rows = 0
bad_rows = 0

with source.open("r", encoding="cp1252", errors="replace", newline="") as src:
    reader = csv.reader(src, delimiter=";", quotechar='"')

    with target.open("w", encoding="utf-8", newline="") as dst:
        writer = csv.writer(
            dst,
            delimiter=";",
            quotechar='"',
            quoting=csv.QUOTE_MINIMAL,
            lineterminator="\n"
        )

        header = next(reader)
        expected_columns = len(header)
        writer.writerow(header)

        for row in reader:
            rows += 1

            if len(row) != expected_columns:
                bad_rows += 1

            cleaned_row = []

            for value in row:
                invalid_chars += value.count("\ufffd")
                corrections += value.count(bad_pattern)

                value = value.replace(bad_pattern, good_pattern)
                cleaned_row.append(value)

            writer.writerow(cleaned_row)

print(f"Archivo creado: {target}")
print(f"Filas procesadas: {rows:,}")
print(f"Columnas esperadas: {expected_columns}")
print(f"Filas con columnas incorrectas: {bad_rows:,}")
print(f"Caracteres invalidos detectados: {invalid_chars:,}")
print(f"Correcciones contextuales aplicadas: {corrections:,}")