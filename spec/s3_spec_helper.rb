require  File.expand_path(File.dirname(__FILE__) + "/../../../../spec/spec_helper")
require 'fakeweb'

def fakeweb_s3_invalid_credentials_response
  response = <<-RESPONSE
HTTP/1.1 403 Forbidden
x-amz-request-id: 11DC11111111111F
x-amz-id-2: FrcXP1Gg1HRQYPvLMuO1gNZ1LQZbY1qkhDScsG1N1s1u1AtiQJS1WRlt1kns1Hng
Content-Type: application/xml
Transfer-Encoding: chunked
Date: Thu, 01 Jul 2010 17:22:51 GMT
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>InvalidAccessKeyId</Code><Message>The AWS Access Key Id you provided does not exist in our records.</Message><RequestId>11DC11111111111F</RequestId><HostId>FrcXP1Gg1HRQYPvLMuO1gNZ1LQZbY1qkhDScsG1N1s1u1AtiQJS1WRlt1kns1Hng</HostId><AWSAccessKeyId>access_key</AWSAccessKeyId></Error>
RESPONSE

  FakeWeb.register_uri(:get, "https://s3.amazonaws.com:443/", :response => response)
end

def fakeweb_s3_valid_credentials_response
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: Rw1qKXuO1stz1k+DL1hxKMSz+oJcAj1XJI1nh1mZwIr1WcUWIchIbl1uC1R+clZm
x-amz-request-id: A111C1B1C11111A1
Date: Thu, 01 Jul 2010 17:22:30 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>myfakecompany</DisplayName></Owner><Buckets><Bucket><Name>my-bucket</Name><CreationDate>2008-11-07T20:58:50.000Z</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://s3.amazonaws.com:443/", :response => response)
end

def fakeweb_s3_access_denied_response(bucket, key='')
  response = <<-RESPONSE
HTTP/1.1 403 Forbidden
x-amz-request-id: 111B1111111D11C1
x-amz-id-2: mCbEs/1rjEG1tAkTH1qlOV11JiMj1Wh+CmD1JQmQsvCJVk1qH1vO/guezo1rAeP1
Content-Type: application/xml
Transfer-Encoding: chunked
Date: Thu, 01 Jul 2010 17:58:06 GMT
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Access Denied</Message><RequestId>111B1111111D11C1</RequestId><HostId>mCbEs/1rjEG1tAkTH1qlOV11JiMj1Wh+CmD1JQmQsvCJVk1qH1vO/guezo1rAeP1</HostId></Error>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/#{key}", :response => response)
end

def fakeweb_s3_missing_bucket_response(bucket)
  response = <<-RESPONSE
HTTP/1.1 404 Not Found
x-amz-request-id: 11111F1111E11E11
x-amz-id-2: tJ+qdcmpUlVmHRtoIsziqLrsfBQpUm1djSsJynrZnHFWJ1pg1b1KnpYNkjPLvWoi
Content-Type: application/xml
Transfer-Encoding: chunked
Date: Thu, 01 Jul 2010 17:58:16 GMT
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
  <Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist</Message><BucketName>#{bucket}</BucketName><RequestId>11111F1111E11E11</RequestId><HostId>tJ+qdcmpUlVmHRtoIsziqLrsfBQpUm1djSsJynrZnHFWJ1pg1b1KnpYNkjPLvWoi</HostId></Error>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/", :response => response)
end

def fakeweb_s3_valid_bucket_response(bucket)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: fT+yotEaIVnclXkeoUgo1UHxR1Ckk+BJMPOvJfa1MHAvLwEBe+CoGvWNiYokafS1
x-amz-request-id: BC11D1FE11A1111A
Date: Thu, 01 Jul 2010 18:05:37 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>#{bucket}</Name><Prefix></Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated></ListBucketResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/", :response => response)
end

def fakeweb_s3_create_bucket_response(bucket)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: Rw1qKXuO1stz1k+DL1hxKMSz+oJcAj1XJI1nh1mZwIr1WcUWIchIbl1uC1R+clZm
x-amz-request-id: A111C1B1C11111A1
Date: Thu, 01 Jul 2010 17:22:30 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>myfakecompany</DisplayName></Owner><Buckets><Bucket><Name>my-bucket</Name><CreationDate>2008-11-07T20:58:50.000Z</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>
RESPONSE

  response2 = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: Rw1qKXuO1stz1k+DL1hxKMSz+oJcAj1XJI1nh1mZwIr1WcUWIchIbl1uC1R+clZm
x-amz-request-id: A111C1B1C11111A1
Date: Thu, 01 Jul 2010 17:22:30 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>myfakecompany</DisplayName></Owner><Buckets>
<Bucket><Name>my-bucket</Name><CreationDate>2008-11-07T20:58:50.000Z</CreationDate></Bucket><Bucket><Name>#{bucket}</Name><CreationDate>2008-11-07T20:58:50.000Z</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://s3.amazonaws.com:443/", [{:response => response}, {:response => response2}])

  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: 0SZz7KnKhhjUccBsqlKBLMbZ0KOIhFUSGl1H1eRpJ24o166yNQlWCwJzSyQcleS/
x-amz-request-id: 212649C8F403AFF7
Date: Thu, 01 Jul 2010 18:25:49 GMT
Location: /#{bucket}
Content-Length: 0
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:put, "https://#{bucket}.s3.amazonaws.com:443/", :response => response)
end

def fakeweb_s3_store_file_response(bucket, key)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: fBhPxl1XoMV1pdcz11r1E1N1ggRdf1xBgUPjtqzYYOJtYPGNUJCxPMOTRodplfs1
x-amz-request-id: 11111D111D1A11F1
Date: Thu, 01 Jul 2010 19:29:39 GMT
ETag: "1c11c1cacf1f1d111fab1ef1e1f1a1ee"
Content-Length: 0
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:put, "https://#{bucket}.s3.amazonaws.com:443/#{key}", :response => response)
end

def fakeweb_s3_delete_file_response(bucket, key)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: KTRr111q1FZntmyI1z+RfQ11Nx1guVGXv1S1H1R1H1kForGA11o1kuavttz/GBvO
x-amz-request-id: B1C111111AEA1111
Date: Thu, 01 Jul 2010 19:35:51 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>webiva-doug2</Name><Prefix>test.txt</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2010-07-01T19:35:26.000Z</LastModified><ETag>&quot;1c11c1cacf1f1d111fab1ef1e1f1a1ee&quot;</ETag><Size>242</Size><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/?prefix=#{key}", :response => response)

  response = <<-RESPONSE
HTTP/1.1 204 No Content
x-amz-id-2: tNC1KN1j1P1s1xwMKHJl1/q/tn1Ur1CPdGtNMYDC1LKEuJd1iQJB1I1aTeAKwvU1
x-amz-request-id: A1D1C1D1D11E1EC1
Date: Thu, 01 Jul 2010 19:33:39 GMT
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:delete, "https://#{bucket}.s3.amazonaws.com:443/#{key}", :response => response)
end

def fakeweb_s3_get_file_response(bucket, key)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: KTRr111q1FZntmyI1z+RfQ11Nx1guVGXv1S1H1R1H1kForGA11o1kuavttz/GBvO
x-amz-request-id: B1C111111AEA1111
Date: Thu, 01 Jul 2010 19:35:51 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>webiva-doug2</Name><Prefix>test.txt</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2010-07-01T19:35:26.000Z</LastModified><ETag>&quot;1c11c1cacf1f1d111fab1ef1e1f1a1ee&quot;</ETag><Size>242</Size><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/?prefix=#{key}", :response => response)

  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: G1Mf1SLuSZ1Y11H1mKzCzEpE1i1skE/1+HLyWaVc+ycu/pU11ekxEhYpQ1mK11k1
x-amz-request-id: 1111C1F1E1D111C1
Date: Thu, 01 Jul 2010 19:52:30 GMT
Last-Modified: Thu, 01 Jul 2010 19:35:26 GMT
ETag: "1c11c1cacf1f1d111fab1ef1e1f1a1ee"
Content-Type: binary/octet-stream
Content-Length: 5
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:head, "https://#{bucket}.s3.amazonaws.com:443/#{key}", :response => response)

  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: G1Mf1SLuSZ1Y11H1mKzCzEpE1i1skE/1+HLyWaVc+ycu/pU11ekxEhYpQ1mK11k1
x-amz-request-id: 1111C1F1E1D111C1
Date: Thu, 01 Jul 2010 19:52:30 GMT
Last-Modified: Thu, 01 Jul 2010 19:35:26 GMT
ETag: "1c11c1cacf1f1d111fab1ef1e1f1a1ee"
Content-Type: binary/octet-stream
Content-Length: 5
Server: AmazonS3

Test
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/#{key}", :response => response)
end

def fakeweb_s3_make_file_public_response(bucket, key)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: r/ORMkErQ1LoJw1Te1kEq1HXHRerV1QalZzzoLMNe/ERQ1Xe/RwkErRxEIxZ+TNQ
x-amz-request-id: F1111AF11AD11111
Date: Thu, 01 Jul 2010 20:02:03 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>myfakecompany</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant></AccessControlList></AccessControlPolicy>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/#{key}?acl", :response => response)

  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: KTRr111q1FZntmyI1z+RfQ11Nx1guVGXv1S1H1R1H1kForGA11o1kuavttz/GBvO
x-amz-request-id: B1C111111AEA1111
Date: Thu, 01 Jul 2010 19:35:51 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>webiva-doug2</Name><Prefix>test.txt</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2010-07-01T19:35:26.000Z</LastModified><ETag>&quot;1c11c1cacf1f1d111fab1ef1e1f1a1ee&quot;</ETag><Size>242</Size><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/?prefix=#{key}", :response => response)

  response = <<-RESPONSE
HTTP/1.1 204 No Content
x-amz-id-2: tNC1KN1j1P1s1xwMKHJl1/q/tn1Ur1CPdGtNMYDC1LKEuJd1iQJB1I1aTeAKwvU1
x-amz-request-id: A1D1C1D1D11E1EC1
Date: Thu, 01 Jul 2010 19:33:39 GMT
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:put, "https://#{bucket}.s3.amazonaws.com:443/#{key}?acl", :response => response)
end

def fakeweb_s3_make_file_private_response(bucket, key)
  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: r/ORMkErQ1LoJw1Te1kEq1HXHRerV1QalZzzoLMNe/ERQ1Xe/RwkErRxEIxZ+TNQ
x-amz-request-id: F1111AF11AD11111
Date: Thu, 01 Jul 2010 20:02:03 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>myfakecompany</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group"><URI>http://acs.amazonaws.com/groups/global/AllUsers</URI></Grantee><Permission>READ</Permission></Grant></AccessControlList></AccessControlPolicy>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/#{key}?acl", :response => response)

  response = <<-RESPONSE
HTTP/1.1 200 OK
x-amz-id-2: KTRr111q1FZntmyI1z+RfQ11Nx1guVGXv1S1H1R1H1kForGA11o1kuavttz/GBvO
x-amz-request-id: B1C111111AEA1111
Date: Thu, 01 Jul 2010 19:35:51 GMT
Content-Type: application/xml
Transfer-Encoding: chunked
Server: AmazonS3

<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>webiva-doug2</Name><Prefix>test.txt</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2010-07-01T19:35:26.000Z</LastModified><ETag>&quot;1c11c1cacf1f1d111fab1ef1e1f1a1ee&quot;</ETag><Size>242</Size><Owner><ID>111111a11111b1c111fa11a111111ea11111d1111d11bed11a11eb11111de111</ID><DisplayName>cykod</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>
RESPONSE

  FakeWeb.register_uri(:get, "https://#{bucket}.s3.amazonaws.com:443/?prefix=#{key}", :response => response)

  response = <<-RESPONSE
HTTP/1.1 204 No Content
x-amz-id-2: tNC1KN1j1P1s1xwMKHJl1/q/tn1Ur1CPdGtNMYDC1LKEuJd1iQJB1I1aTeAKwvU1
x-amz-request-id: A1D1C1D1D11E1EC1
Date: Thu, 01 Jul 2010 19:33:39 GMT
Server: AmazonS3

RESPONSE

  FakeWeb.register_uri(:put, "https://#{bucket}.s3.amazonaws.com:443/#{key}?acl", :response => response)
end
