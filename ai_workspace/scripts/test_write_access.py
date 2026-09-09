import os
import sys

output_file = r"c:\Users\M HATTA\.gemini\antigravity\scratch\nubi_final\ai_workspace\scripts\test_python_write.txt"
try:
    with open(output_file, 'w') as f:
        f.write(f"Python path: {sys.executable}\n")
        f.write(f"Python version: {sys.version}\n")
        f.write("Dependencies check:\n")
        try:
            import pandas
            f.write(f"Pandas ok: {pandas.__version__}\n")
        except ImportError:
            f.write("Pandas missing\n")
        try:
            import yaml
            f.write("Yaml ok\n")
        except ImportError:
            f.write("Yaml missing\n")
    print("Write successful")
except Exception as e:
    # We can't see this print if the terminal is failing, but we check for file presence
    pass
