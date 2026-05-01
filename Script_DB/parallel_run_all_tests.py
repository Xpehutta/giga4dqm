import psycopg2
from psycopg2 import Error
from multiprocessing import Pool

# Connection parameters
DB_PARAMS = {
    "host": "tsles-bdm000025.esrt.sber.ru",
    "database": "devadbbdm",
    "user": "u_sklgrnplm_s_as_t_didsd_ppl",
    "password": "123",
    "port": "5432"
}

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


# Change params if needed
queries = [
    "select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test1 (1000000,2000000);",
    "select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test2 (1000,100,100);",
    "select * from s_grnplm_as_t_didsd_nnn_db_tmd.fn_run_test3 (100000,50,10000);",
]

with Pool(processes=3) as p:
    results = p.map(run_query, queries)

for result in results:
    print(result)