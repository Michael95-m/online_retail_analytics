import clickhouse_connect
import pandas as pd
from pathlib import Path
from dotenv import load_dotenv
import os
import logging

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def create_clickhouse_client():
    """
    Creates a ClickHouse client using environment variables.

    Returns:
        clickhouse_connect.Client: The ClickHouse client.
    """

    host = os.getenv("CLICKHOUSE_HOST")
    port = int(os.getenv("CLICKHOUSE_PORT"))
    username = os.getenv("CLICKHOUSE_USER")
    password = os.getenv("CLICKHOUSE_PASSWORD")

    return clickhouse_connect.get_client(
        host=host, port=port, username=username, password=password
    )


def read_excel_file(file_path: Path, sheet_name: str) -> pd.DataFrame:
    """
    Reads an Excel file and returns a DataFrame.

    Args:
        file_path (Path): The path to the Excel file.
        sheet_name (str): The name of the sheet to read.

    Returns:
        pd.DataFrame: The DataFrame containing the data from the specified sheet.
    """
    return pd.read_excel(file_path, sheet_name=sheet_name)


def drop_table_if_exists(client, table_name: str):
    """
    Drops a table in ClickHouse if it exists.

    Args:
        client: The ClickHouse client.
        table_name (str): The name of the table to drop.
    """
    client.command(f"DROP TABLE IF EXISTS {table_name}")


def create_table(client, sql_file_path: Path):
    """
    Creates a table in ClickHouse using the SQL from a file.

    Args:
        client: The ClickHouse client.
        sql_file_path (Path): The path to the SQL file containing the CREATE TABLE statement.
    """
    with open(sql_file_path, "r") as f:
        create_table_sql = f.read()
    client.command(create_table_sql)


def rename_columns(df: pd.DataFrame, columns: dict) -> pd.DataFrame:
    """
    Renames the columns of a DataFrame.

    Args:
        df (pd.DataFrame): The DataFrame whose columns are to be renamed.
        columns (dict): A dictionary mapping old column names to new column names.

    Returns:
        pd.DataFrame: The DataFrame with renamed columns.
    """
    return df.rename(columns=columns)


def cast_column_types(df: pd.DataFrame, type_dict: dict) -> pd.DataFrame:
    """
    Casts the column types of a DataFrame.

    Args:
        df (pd.DataFrame): The DataFrame whose column types are to be cast.
        type_dict (dict): A dictionary mapping column names to their desired types.

    Returns:
        pd.DataFrame: The DataFrame with casted column types.
    """
    return df.astype(type_dict)


def insert_data_into_clickhouse(client, table: str, database: str, df: pd.DataFrame):
    """
    Inserts data from a DataFrame into a ClickHouse table.

    Args:
        client: The ClickHouse client.
        table (str): The name of the table to insert data into.
        database (str): The name of the database containing the table.
        df (pd.DataFrame): The DataFrame containing the data to insert.
    """
    client.insert_df(table=table, database=database, df=df)


def main():
    logging.info("Starting data loading process...")
    load_dotenv()  # Load environment variables from .env file

    ## Read data from the Excel file
    csv_file_path = Path(__file__).parent.parent / "data" / "online_retail_II.xlsx"
    logging.info(f"Reading data from Excel file: {csv_file_path}")
    df_2009_to_2010 = read_excel_file(csv_file_path, "Year 2009-2010")
    df_2010_to_2011 = read_excel_file(csv_file_path, "Year 2010-2011")
    df = pd.concat([df_2009_to_2010, df_2010_to_2011])

    ## rename the columns to match the ClickHouse table schema
    logging.info("Renaming columns to match ClickHouse table schema...")
    columns = {
        "Invoice": "invoice_id",
        "StockCode": "stock_code",
        "Description": "description",
        "Quantity": "quantity",
        "InvoiceDate": "invoice_date",
        "Price": "unit_price",
        "Customer ID": "customer_id",
        "Country": "country",
    }
    df = rename_columns(df, columns)

    ## type casting to match the ClickHouse table schema
    logging.info("Casting column types to match ClickHouse table schema...")
    type_dict = {
        "invoice_id": "string",  ## # mixed types (int/str), no nulls
        "stock_code": "string",  # no nulls, but string is fine either way
        "description": "string",  # contains nulls
        "quantity": "int",
        "unit_price": "float",
        "customer_id": "Int64",  # contains nulls
        "country": "string",
    }
    df = cast_column_types(df, type_dict)

    with create_clickhouse_client() as client:
        logging.info("Connected to ClickHouse database.")

        # delete the existing table if it exists
        table_name = "retail.raw_invoice"
        logging.info(f"Dropping existing table {table_name} if it exists...")
        drop_table_if_exists(client, table_name)

        # Create the table
        logging.info(f"Creating the table {table_name} in ClickHouse...")
        create_table_sql_path = Path(__file__).parent / "ddl" / "raw_invoice.sql"
        create_table(client, create_table_sql_path)

        # Insert data into ClickHouse table
        logging.info(f"Inserting data into table {table_name}...")
        table = "raw_invoice"
        database = "retail"
        insert_data_into_clickhouse(client, table, database, df)

    logging.info("Data loading process completed successfully.")


if __name__ == "__main__":
    main()
