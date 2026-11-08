
from pyspark.sql import SparkSession
from delta import configure_spark_with_delta_pip


def create_spark_session(app_name: str) -> SparkSession:
    """
    Create a Spark Session configured with Delta Lake support.
    """

    builder = (
        SparkSession.builder
        .appName(app_name)
        .master("local[*]")
        .config(
            "spark.sql.extensions",
            "io.delta.sql.DeltaSparkSessionExtension"
        )
        .config(
            "spark.sql.catalog.spark_catalog",
            "org.apache.spark.sql.delta.catalog.DeltaCatalog"
        )
    )

    spark = configure_spark_with_delta_pip(
        builder,
        extra_packages=[
            "org.postgresql:postgresql:42.7.7"
        ]
    ).getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    return spark
