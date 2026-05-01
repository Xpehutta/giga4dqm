import psycopg2
from psycopg2 import Error
from multiprocessing import Pool

# Connection parameters
DB_PARAMS = {
    "host": "tpgds-capgp0008.delta.sbrf.ru",
    "database": "dev_adb_bare",
    "user": "gpadmin",
    "password": "a8S1LgxsOJjH8pJoZ8UT",
    "port": "5432"
}


# Parallelism
n=96


def run_query(query):
    try:
        # Connect to the database
        conn = psycopg2.connect(**DB_PARAMS)
        print("Database connected successfully")

        # Open a cursor to perform database operations
        cur = conn.cursor()

        # Query the database
        cur.execute(query)
        # Fetch all the results
        records = cur.fetchall()
        print("Fetched records:", records)

        # Make the changes to the database persistent
        conn.commit()
        print("Changes committed")

    except (Exception, Error) as error:
        print(f"Error while working with PostgreSQL: {error}")

    finally:
        # Close communication with the database
        if conn:
            cur.close()
            conn.close()
            print("Database connection closed.")

queries = []
for _ in range(n):
    # Change params if needed
    queries.append("select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_calc_fltr_test1();")
print(queries)

with Pool(processes=n) as p:
    results = p.map(run_query, queries)

for result in results:
    print(result)