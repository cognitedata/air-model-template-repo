from cognite.client import CogniteClient
from cognite.client.data_classes.datapoints import Datapoints
from cognite.client.testing import monkeypatch_cognite_client

from functions.templatefunction.function.handler import handle


def test_handle():
    # Enter tests here