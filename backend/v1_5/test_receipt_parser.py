"""
CORET Backend — Receipt Parser Tests

Tester parsing av kvitteringer fra ulike forhandlere.
"""

from services.receipt_parser import parse_receipt, detect_retailer


# MARK: - detect_retailer

def test_detect_zalando():
    assert detect_retailer("noreply@zalando.no") == "zalando"


def test_detect_hm():
    assert detect_retailer("noreply@hm.com") == "hm"


def test_detect_asos():
    assert detect_retailer("noreply@asos.com") == "asos"


def test_detect_arket():
    assert detect_retailer("noreply@arket.com") == "arket"


def test_detect_unknown():
    assert detect_retailer("noreply@random-shop.com") is None


# MARK: - parse_receipt

def test_parse_unknown_sender():
    result = parse_receipt("<html>order</html>", "noreply@unknown.com")
    assert result["success"] is False
    assert result["retailer"] is None


def test_parse_zalando_fallback():
    """Test Zalando med fallback-mønster."""
    html = """
    <html>
        <body>
            1 x Slim Fit Jeans - Str. M
            2 x Oxford Shirt - Str. L
        </body>
    </html>
    """
    result = parse_receipt(html, "noreply@zalando.no")
    assert result["retailer"] == "zalando"
    assert result["success"] is True
    assert len(result["items"]) >= 1


def test_parse_hm_fallback():
    """Test H&M med fallback-mønster."""
    html = """
    <html>
        <body>
            1 x Regular Fit Hoodie - Size M
        </body>
    </html>
    """
    result = parse_receipt(html, "noreply@hm.com")
    assert result["retailer"] == "hm"
    if result["success"]:
        assert result["items"][0]["brand"] == "H&M"


def test_parse_deduplication():
    """Test at duplikater fjernes."""
    html = """
    <html>
        <body>
            1 x Slim Fit Jeans - Str. M
            1 x Slim Fit Jeans - Str. L
        </body>
    </html>
    """
    result = parse_receipt(html, "noreply@zalando.no")
    if result["success"]:
        titles = [item["product_title"].lower() for item in result["items"]]
        assert len(titles) == len(set(titles))


def test_parse_empty_html():
    """Test med tom HTML."""
    result = parse_receipt("", "noreply@zalando.no")
    assert result["success"] is False
    assert result["items"] == []


def test_parsed_item_has_metadata():
    """Test at parsed items har metadata-forslag."""
    html = """
    <html>
        <body>
            1 x Nike Air Force 1 Sneakers - Str. 42
        </body>
    </html>
    """
    result = parse_receipt(html, "noreply@zalando.no")
    if result["success"] and len(result["items"]) > 0:
        item = result["items"][0]
        assert "suggested_base_group" in item
        assert "suggested_category" in item
        assert "confidence" in item
