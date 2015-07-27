require 'minitest/autorun'
require 'proxy/response'

class TestProxyResponse < MiniTest::Test
  def test_response_status_parsing
    response = response_with_line 'HTTP/1.1 200 OK'
    assert_equal response.headers, ['HTTP/1.1 200 OK']
    assert_equal response.code, '200 OK'
  end

  def test_content_type_parsing
    response = response_with_line 'Content-Type: text/xml'
    assert_equal response.headers, ['Content-Type: text/xml']
    assert_equal response.content_type, 'text/xml'
  end

  def test_content_length_parsing
    response = response_with_line 'Content-Length: 1024'
    assert_equal response.headers, ['Content-Length: 1024']
    assert_equal response.content_length, 1024
  end

  def test_reaching_end_of_headers
    response = response_with_line 'HTTP/1.1 200 OK'
    refute response.headers_done

    response << ''
    assert response.headers_done
  end

  def test_parsing_response_body
    body = 'This line goes into the body'

    response = response_with_line 'HTTP/1.1 200 OK'
    response << ''
    response << body

    assert_equal response.body, body
  end

  def test_textual
    text_response = response_with_line 'Content-Type: text/xml'
    image_response = response_with_line 'Content-Type: image/png'

    assert text_response.textual?
    refute image_response.textual?
  end

  private

  def response_with_line(line)
    response = Proxy::Response.new
    response << line
    response
  end
end
