
from src.spark.spark_session import create_spark_session


def main():
    spark = create_spark_session("BankingDataLakehouse")

    bronze_tables = [
        "core/categories",
        "core/customer_addresses",
        "core/customers",
        "core/products",
        "core/sellers",
        "inventory/stock",
        "inventory/warehouses",
        "logistics/shipments",
        "marketing/campaigns",
        "marketing/customer_campaigns",
        "sales/order_items",
        "sales/orders",
        "sales/payments",
        "sales/refunds"
    ]

    print("\nBRONZE LAYER VALIDATION")

    for table in bronze_tables:
        path = f"data/bronze/{table}"

        df = spark.read.format("delta").load(path)

        print(f"\nTable: {table}")
        print(f"Columns: {len(df.columns)}")
        print(f"Records: {df.count()}")

    print("\nBronze validation completed!")

    spark.stop()


if __name__ == "__main__":
    main()
