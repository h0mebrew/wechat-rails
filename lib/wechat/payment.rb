require 'wechat/utils'

class Wechat::Payment
  API_MCH_BASE = "https://api.mch.weixin.qq.com/pay/"
  attr_reader :client, :appid, :secret, :mchid, :key, :notify_url

  def initialize(appid, secret, mchid, key, notify_url)
    @client = Wechat::Client.new(API_MCH_BASE)
    @appid = appid
    @secret = secret
    @mchid = mchid
    @key = key
    @notify_url = notify_url
  end

  #response
  # {
  #   "return_code"=>"SUCCESS",
  #   "return_msg"=>"OK",
  #   "appid"=>"wxb74ad11807f36263",
  #   "mch_id"=>"10024328",
  #   "nonce_str"=>"P4OwClH9w8JCJ7e0",
  #   "sign"=>"12A22ADF3BA1EE6F2FBD48B7B1243909",
  #   "result_code"=>"SUCCESS",
  #   "prepay_id"=>"wx20141108154348ed4994cf2d0999736714",
  #   "trade_type"=>"NATIVE",
  #   "code_url"=>"weixin://wxpay/bizpayurl?sr=n9lWgQE"
  # }

  def unified_order(params)
    Wechat::Utils.required_check(params, [:body, :out_trade_no, :total_fee, :spbill_create_ip, :trade_type])
    params.reverse_merge! appid: appid,
                          mch_id: mchid,
                          notify_url: notify_url,
                          nonce_str: Wechat::Utils.get_nonce_str
    params[:sign] = Wechat::Utils.get_sign(params, key)
    xml_data = Wechat::Utils.hash_to_xml(params)
    @client.post("unifiedorder", xml_data, as: :xml)
  end

  def get_native_dynamic_qrcode(params)
    result = unified_order(params.merge(trade_type: 'NATIVE'))
    result[:code_url]
  end

  def get_js_api_params(params)
    result = unified_order(params.merge(trade_type: 'JSAPI'))
    params = {
      appId: appid,
      timeStamp: Wechat::Utils.get_timestamp,
      nonceStr: Wechat::Utils.get_nonce_str,
      package: "prepay_id=#{result[:prepay_id]}",
      signType: "MD5"
    }
    params[:paySign] = Wechat::Utils.get_sign(params, key)
    params
  end

  def verify?(params)
    Wechat::Utils.get_sign(params, key) == params[:sign]
  end
end
