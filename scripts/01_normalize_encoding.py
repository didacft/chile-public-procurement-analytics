from pathlib import Path

source = Path("data/raw/health/2025_H1/07OCTratoDirecto.csv")
target = Path("data/processed/health/2025_H1/07OCTratoDirecto_utf8.csv")

target.parent.mkdir(parents=True, exist_ok=True)

bad_pattern = "CONEXI\u00C3?N HEX\u00C3\uFFFDGONO"
good_pattern = "CONEXI\u00D3N HEX\u00C1GONO"

invalid_chars = 0
corrections = 0
remaining_invalid = 0

with source.open("r", encoding="cp1252", errors="replace", newline="") as src:
    with target.open("w", encoding="utf-8", newline="") as dst:
        for line in src:
            invalid_chars += line.count("\ufffd")
            corrections += line.count(bad_pattern)

            line = line.replace(bad_pattern, good_pattern)

            remaining_invalid += line.count("\ufffd")
            dst.write(line)

print(f"Archivo creado: {target}")
print(f"Caracteres invalidos detectados: {invalid_chars:,}")
print(f"Correcciones contextuales aplicadas: {corrections:,}")
print(f"Caracteres invalidos restantes: {remaining_invalid:,}")