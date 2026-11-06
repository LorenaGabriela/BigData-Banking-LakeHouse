
from src.spark.spark_session import create_spark_session
from src.ingestion.postgres_reader import read_postgres_table


def main():
    spark = create_spark_session("BankingDataLakehouse")

    print("Spark Version:", spark.version)
    print("Spark Session Created Successfully!")

    # Read a table from PostgreSQL
    df = read_postgres_table(
        spark,
        "sales.orders"
    )

    print("PostgreSQL data loaded successfully!")

    df.printSchema()
    df.show(10, truncate=False)

    print("Number of records:", df.count())

    # Save raw data to the Bronze layer
    bronze_path = "data/bronze/orders"

    df.write \
        .format("delta") \
        .mode("overwrite") \
        .save(bronze_path)

    print("Data successfully saved to Bronze layer!")

    # Read data back from Delta Lake
    bronze_df = spark.read \
        .format("delta") \
        .load(bronze_path)

    print("Bronze layer verification:")
    bronze_df.show(truncate=False)

    print("Bronze record count:", bronze_df.count())

    spark.stop()


if __name__ == "__main__":
    main()
