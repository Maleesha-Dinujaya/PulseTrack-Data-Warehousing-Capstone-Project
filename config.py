"""Central configuration for the PulseTrack data warehousing capstone.

Nothing secret is stored in this file. The database connection string is read
from the ``PULSETRACK_DB_URI`` environment variable, with a harmless local
default so the scripts still run on a fresh clone.

Set it in your shell, or copy ``.env.example`` to ``.env`` and export it:

    export PULSETRACK_DB_URI="postgresql://user:password@localhost:5432/pulsetrack_raw"
"""

import os

# --- Database ----------------------------------------------------------------

#: SQLAlchemy connection string for the warehouse.
DB_URI = os.getenv(
    "PULSETRACK_DB_URI",
    "postgresql://postgres:postgres@localhost:5432/pulsetrack_raw",
)

# --- Project paths -----------------------------------------------------------

#: Absolute path to the repository root (the folder that holds this file).
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

#: Relational export -- 11 CSV files, the primary source.
DATA_DIR = os.path.join(BASE_DIR, "data")

#: MongoDB "PartnerHub/CRM" dump -- JSON Lines, nested reference data.
MONGO_DIR = os.path.join(BASE_DIR, "mongo")

#: Kafka-style conversion stream -- one record per line.
STREAM_DIR = os.path.join(BASE_DIR, "stream")
STREAM_LOG_FILE = os.path.join(STREAM_DIR, "pulsetrack_conversions.log")

#: Rows read per batch when loading the large CSV / stream files.
CHUNK_SIZE = 50_000
