"""
SQL Practice Runner using DuckDB

Usage:
    python run_sql.py <path_to_sql_file>
    python run_sql.py -c "SELECT COUNT(*) FROM core_customers;"
    python run_sql.py --tables

Example:
    python run_sql.py 01-fundamentals/01_select.sql
"""

import sys
import os
import time
import duckdb

# ============================================================
# CONFIGURATION
# ============================================================

# Enable UTF-8 encoding on Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


# ============================================================
# TERMINAL COLORS
# ============================================================

class Color:
    RESET = "\033[0m"
    BOLD = "\033[1m"

    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    MAGENTA = "\033[95m"
    WHITE = "\033[97m"
    GRAY = "\033[90m"


# Enable ANSI colors on Windows
if sys.platform == "win32":
    os.system("")


def color_text(text, color):
    return f"{color}{text}{Color.RESET}"


def print_line(char="=", width=90, color=Color.GRAY):
    print(color_text(char * width, color))


def print_header(title):
    print()
    print_line("=", 90, Color.CYAN)
    print(color_text(f"  {title}", Color.BOLD + Color.CYAN))
    print_line("=", 90, Color.CYAN)


def print_status(status, message):
    colors = {
        "SUCCESS": Color.GREEN,
        "ERROR": Color.RED,
        "WARNING": Color.YELLOW,
        "INFO": Color.CYAN,
    }

    symbols = {
        "SUCCESS": "✔",
        "ERROR": "✘",
        "WARNING": "!",
        "INFO": "ℹ",
    }

    color = colors.get(status, Color.WHITE)
    symbol = symbols.get(status, "*")

    print(f"{color}{symbol} [{status}]{Color.RESET} {message}")


# ============================================================
# DATABASE CONNECTION
# ============================================================

def get_connection():

    script_dir = os.path.dirname(os.path.abspath(__file__))

    project_root = os.path.abspath(
        os.path.join(script_dir, "..")
    )

    dataset_dir = os.path.join(
        project_root,
        "datasets",
        "mock-banking"
    )

    con = duckdb.connect()
    table_names = []

    print_header("DATABASE INITIALIZATION")

    if not os.path.exists(dataset_dir):
        print_status(
            "ERROR",
            f"Dataset directory not found: {dataset_dir}"
        )
        return con, table_names

    csv_files = sorted(
        fname
        for fname in os.listdir(dataset_dir)
        if fname.lower().endswith(".csv")
    )

    for fname in csv_files:

        table_name = os.path.splitext(fname)[0]

        csv_path = os.path.join(
            dataset_dir,
            fname
        ).replace("\\", "/")

        # Escape single quotes in file path
        safe_path = csv_path.replace("'", "''")

        # Escape double quotes in table name
        safe_table_name = table_name.replace('"', '""')

        try:

            con.execute(
                f'''
                CREATE OR REPLACE VIEW "{safe_table_name}"
                AS
                SELECT *
                FROM read_csv_auto('{safe_path}')
                '''
            )

            table_names.append(table_name)

            print_status(
                "SUCCESS",
                f"Loaded: {table_name}"
            )

        except Exception as e:

            print_status(
                "ERROR",
                f"Cannot load {fname}: {e}"
            )

    print_line("-", 90, Color.GRAY)

    print_status(
        "SUCCESS",
        f"Successfully loaded {len(table_names)}/{len(csv_files)} CSV files."
    )

    return con, table_names


# ============================================================
# TABLE INFORMATION
# ============================================================

def show_tables(con, table_names):

    print_header("AVAILABLE TABLES - MOCK BANKING DATASET")

    if not table_names:

        print_status(
            "WARNING",
            "No tables found."
        )

        return

    total_rows = 0

    print(
        f"{'TABLE NAME':<40}"
        f"{'ROW COUNT':>20}"
    )

    print_line("-", 65)

    for table_name in table_names:

        try:

            count = con.execute(
                f'SELECT COUNT(*) FROM "{table_name}"'
            ).fetchone()[0]

            total_rows += count

            print(
                f"{table_name:<40}"
                f"{count:>20,}"
            )

        except Exception as e:

            print_status(
                "ERROR",
                f"Cannot count {table_name}: {e}"
            )

    print_line("-", 65)

    print(
        f"{'TOTAL ROWS':<40}"
        f"{total_rows:>20,}"
    )

    print_line("=", 90, Color.CYAN)

    print_status(
        "SUCCESS",
        f"{len(table_names)} table(s) loaded successfully."
    )


# ============================================================
# QUERY RESULT DISPLAY
# ============================================================

def display_result(df):

    if df.empty:

        print_status(
            "WARNING",
            "Query executed successfully but returned no rows."
        )

        return 0

    print()

    # Display query result
    print(
        color_text(
            df.to_string(index=False),
            Color.WHITE
        )
    )

    print()

    print_line("-", 90, Color.GRAY)

    print_status(
        "INFO",
        f"Rows returned: {len(df):,}"
    )

    print_status(
        "INFO",
        f"Columns returned: {len(df.columns):,}"
    )

    return len(df)


# ============================================================
# EXECUTE SINGLE QUERY
# ============================================================

def execute_query(con, query, title, index=None):

    print()

    print_line("-", 90, Color.BLUE)

    if index is not None:

        print(
            color_text(
                f"  QUERY #{index}: {title}",
                Color.BOLD + Color.BLUE
            )
        )

    else:

        print(
            color_text(
                f"  {title}",
                Color.BOLD + Color.BLUE
            )
        )

    print_line("-", 90, Color.BLUE)

    start_time = time.perf_counter()

    try:

        result = con.execute(query)

        # Convert result to DataFrame
        df = result.df()

        elapsed = time.perf_counter() - start_time

        row_count = display_result(df)

        print_status(
            "SUCCESS",
            f"Execution completed in {elapsed:.4f} seconds."
        )

        return {
            "success": True,
            "rows": row_count,
            "time": elapsed
        }

    except Exception as e:

        elapsed = time.perf_counter() - start_time

        print_status(
            "ERROR",
            "SQL execution failed."
        )

        print()

        print(
            color_text(
                f"  Error details: {e}",
                Color.RED
            )
        )

        print_status(
            "INFO",
            f"Failed after {elapsed:.4f} seconds."
        )

        return {
            "success": False,
            "rows": 0,
            "time": elapsed
        }


# ============================================================
# PARSE SQL FILE
# ============================================================

def parse_sql_file(sql_content):

    queries = []

    current_query = []
    current_comments = []

    for line in sql_content.splitlines():

        stripped = line.strip()

        # Skip empty lines
        if not stripped:
            current_query.append(line)
            continue

        # Collect SQL comments
        if stripped.startswith("--"):

            if not any(
                item.strip()
                and not item.strip().startswith("--")
                for item in current_query
            ):
                current_comments.append(
                    stripped.lstrip("-").strip()
                )
            else:
                current_query.append(line)

            continue

        # Split SQL statements by semicolon
        parts = line.split(";")

        for i, part in enumerate(parts):

            if part.strip():
                current_query.append(part)

            if i < len(parts) - 1:

                query = "\n".join(
                    current_query
                ).strip()

                if query:

                    title = " | ".join(
                        current_comments[:2]
                    )

                    if not title:
                        title = f"SQL Query #{len(queries) + 1}"

                    queries.append({
                        "title": title,
                        "query": query
                    })

                current_query = []
                current_comments = []

    # Handle last query without semicolon
    query = "\n".join(
        current_query
    ).strip()

    if query:

        title = " | ".join(
            current_comments[:2]
        )

        if not title:
            title = f"SQL Query #{len(queries) + 1}"

        queries.append({
            "title": title,
            "query": query
        })

    return queries


# ============================================================
# EXECUTE SQL FILE
# ============================================================

def execute_sql_file(con, sql_file):

    if not os.path.exists(sql_file):

        script_dir = os.path.dirname(
            os.path.abspath(__file__)
        )

        alt_path = os.path.join(
            script_dir,
            sql_file
        )

        if os.path.exists(alt_path):
            sql_file = alt_path

        else:

            print_status(
                "ERROR",
                f"SQL file not found: {sql_file}"
            )

            return False

    try:

        with open(
            sql_file,
            "r",
            encoding="utf-8"
        ) as f:

            sql_content = f.read()

    except Exception as e:

        print_status(
            "ERROR",
            f"Cannot read SQL file: {e}"
        )

        return False

    queries = parse_sql_file(sql_content)

    if not queries:

        print_status(
            "WARNING",
            "No SQL queries found in file."
        )

        return False

    print_header("SQL PRACTICE RUNNER")

    print_status(
        "INFO",
        f"File: {sql_file}"
    )

    print_status(
        "INFO",
        f"Total queries: {len(queries)}"
    )

    # Execution statistics
    success_count = 0
    error_count = 0
    total_rows = 0
    total_time = 0

    for idx, item in enumerate(queries, 1):

        result = execute_query(
            con=con,
            query=item["query"],
            title=item["title"],
            index=idx
        )

        total_time += result["time"]
        total_rows += result["rows"]

        if result["success"]:
            success_count += 1
        else:
            error_count += 1

    # Final summary
    print_header("EXECUTION SUMMARY")

    print(
        f"{'Total queries':<30}"
        f"{len(queries):>10}"
    )

    print(
        color_text(
            f"{'Successful queries':<30}{success_count:>10}",
            Color.GREEN
        )
    )

    print(
        color_text(
            f"{'Failed queries':<30}{error_count:>10}",
            Color.RED if error_count else Color.GREEN
        )
    )

    print(
        f"{'Total rows returned':<30}"
        f"{total_rows:>10,}"
    )

    print(
        f"{'Total execution time':<30}"
        f"{total_time:>10.4f} sec"
    )

    print_line("=", 90, Color.CYAN)

    if error_count == 0:

        print_status(
            "SUCCESS",
            "All SQL queries executed successfully!"
        )

    else:

        print_status(
            "WARNING",
            f"Execution finished with {error_count} error(s)."
        )

    print()

    return error_count == 0


# ============================================================
# EXECUTE INLINE QUERY
# ============================================================

def execute_inline_query(con):

    if len(sys.argv) < 3:

        print_status(
            "ERROR",
            'Missing query after -c. Example: python run_sql.py -c "SELECT 1"'
        )

        return False

    query = sys.argv[2]

    print_header("INLINE SQL QUERY")

    print(
        color_text(
            query,
            Color.YELLOW
        )
    )

    result = execute_query(
        con=con,
        query=query,
        title="INLINE QUERY"
    )

    return result["success"]


# ============================================================
# HELP
# ============================================================

def show_help():

    print_header("SQL PRACTICE RUNNER - HELP")

    print(
        """
Usage:

  1. Execute SQL file:

     python run_sql.py <file.sql>

  2. Execute inline SQL:

     python run_sql.py -c "SELECT COUNT(*) FROM core_customers;"

  3. Show available tables:

     python run_sql.py --tables

Examples:

  python run_sql.py 01-fundamentals/01_select.sql

  python run_sql.py -c "SELECT * FROM core_customers LIMIT 10;"

  python run_sql.py --tables
"""
    )


# ============================================================
# MAIN
# ============================================================

def main():

    if len(sys.argv) < 2:

        show_help()
        return

    try:

        con, table_names = get_connection()

    except Exception as e:

        print_status(
            "ERROR",
            f"Database initialization failed: {e}"
        )

        sys.exit(1)

    try:

        command = sys.argv[1]

        if command == "--tables":

            show_tables(
                con,
                table_names
            )

        elif command == "-c":

            success = execute_inline_query(con)

            if not success:
                sys.exit(1)

        elif command in ("-h", "--help"):

            show_help()

        else:

            success = execute_sql_file(
                con,
                command
            )

            if not success:
                sys.exit(1)

    finally:

        con.close()


if __name__ == "__main__":
    main()
