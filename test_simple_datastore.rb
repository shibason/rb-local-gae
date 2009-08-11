require 'test/unit'
require 'local_gae'
require 'simple_datastore'

class TC_SimpleDatastore < Test::Unit::TestCase
  # 各テストメソッドの前処理
  def setup
    # ローカルGAEサービスを起動
    LocalGAE::Service.start(:no_storage => true)
  end

  # 各テストメソッドの後処理
  def teardown
    # ローカルGAEサービスを停止
    LocalGAE::Service.stop
    # 一度サービスを停止するので、@@serviceを無理矢理リセットしておく
    SimpleDatastore.send(:remove_class_variable, :@@service)
  end

  # 初期状態のテスト
  def test_1_init
    assert_raise(NameError, '初期状態で@@serviceは未定義') do
      SimpleDatastore.send(:class_variable_get, :@@service)
    end
    assert_equal(0, SimpleDatastore.keys.length, '初期状態でkeysの長さは0')
    assert_equal(0, SimpleDatastore.values.length, '初期状態でvaluesの長さは0')
  end

  # データ格納のテスト
  def test_2_set
    assert_equal(100, SimpleDatastore[:int] = 100, '整数の格納')
    assert_equal(288230376151711744,
                 SimpleDatastore[:bigint] = 288230376151711744,
                 '大きな整数の格納')
    #assert_equal(3.141592, SimpleDatastore[:float] = 3.141592,
    #             '浮動小数点数の格納')
    assert_equal(2.5, SimpleDatastore[:float] = 2.5, '浮動小数点数の格納')
    assert_equal(3.141592.to_s, SimpleDatastore[:float_str] = 3.141592.to_s,
                 '文字列に変換した浮動小数点数の格納')
    assert_equal('Hello world', SimpleDatastore[:string] = 'Hello world',
                 '文字列の格納')
    assert_equal('a' * 1024, SimpleDatastore[:text] = 'a' * 1024,
                 '大きな文字列の格納')
    assert_equal([ 1, 2, 3, 'a', 'b', 'c' ],
                 SimpleDatastore[:array] = [ 1, 2, 3, 'a', 'b', 'c' ],
                 '配列の格納')
    assert_raise(NativeException, 'シンボルの格納はできない') do
      SimpleDatastore[:symbol] = :foobar
    end
    assert_raise(NativeException, 'ハッシュの格納はできない') do
      SimpleDatastore[:hash] = { :a => 1, :b => 'c' }
    end
    assert_raise(NativeException, 'その他のオブジェクトの格納はできない') do
      SimpleDatastore[:object] = Object.new
    end
  end

  # データ取得のテスト
  def test_3_get
    test_2_set
    assert_equal(100, SimpleDatastore[:int], '整数の取得')
    assert_equal(288230376151711744, SimpleDatastore[:bigint],
                 '大きな整数の取得')
    #assert_equal(3.141592, SimpleDatastore[:float], '浮動小数点数の取得')
    assert_equal(2.5, SimpleDatastore[:float], '浮動小数点数の取得')
    assert_equal(3.141592, SimpleDatastore[:float_str].to_f,
                 '文字列に変換した浮動小数点数の取得')
    assert_equal('Hello world', SimpleDatastore[:string], '文字列の取得')
    assert_equal('a' * 1024, SimpleDatastore[:text], '大きな文字列の取得')
    assert_equal([ 1, 2, 3, 'a', 'b', 'c' ], SimpleDatastore[:array],
                 '配列の取得')
    assert_nil(SimpleDatastore[:notexist], '存在しないデータの取得')
  end

  # キーの存在確認のテスト
  def test_4_has_key
    test_2_set
    assert(SimpleDatastore.has_key?(:int))
    assert(SimpleDatastore.has_key?(:bigint))
    assert(SimpleDatastore.has_key?(:float))
    assert(SimpleDatastore.has_key?(:float_str))
    assert(SimpleDatastore.has_key?(:string))
    assert(SimpleDatastore.has_key?(:text))
    assert(SimpleDatastore.has_key?(:array))
    assert(!SimpleDatastore.has_key?(:notexist), '存在しないキーの確認')
  end

  # データ削除のテスト
  def test_5_delete
    test_2_set
    assert_equal(100, SimpleDatastore[:int])
    assert_nil(SimpleDatastore.delete(:int))
    assert_nil(SimpleDatastore[:int])
    assert_nil(SimpleDatastore.delete(:notexist), '存在しないデータの削除')
  end

  # キーの配列取得のテスト
  def test_6_keys
    test_2_set
    assert_equal([ 'int', 'bigint', 'float', 'float_str',
                   'string', 'text', 'array' ].sort,
                 SimpleDatastore.keys.sort)
    assert_nil(SimpleDatastore.delete(:int))
    assert_nil(SimpleDatastore.delete(:string))
    assert_nil(SimpleDatastore.delete(:array))
    assert_equal([ 'bigint', 'float', 'float_str', 'text' ].sort,
                 SimpleDatastore.keys.sort)
  end

  # 値の配列取得のテスト
  def test_7_values
    test_2_set
    expected_values = [ 100, 288230376151711744, 2.5, 3.141592.to_s,
                        'Hello world', 'a' * 1024, [ 1, 2, 3, 'a', 'b', 'c' ] ]
    values = SimpleDatastore.values
    assert_equal(expected_values.length, values.length)
    values.each do |value|
      assert(expected_values.include?(value))
    end
  end
end

# ストレージへの書き込みを伴うテスト
class TC_SimpleDatastore_with_storage < Test::Unit::TestCase
  def setup
    LocalGAE::Service.start
  end

  def teardown
    LocalGAE::Service.stop
    SimpleDatastore.send(:remove_class_variable, :@@service)
  end

  def test_1_set
    assert_nothing_raised do
      SimpleDatastore.keys.each do |key|
        SimpleDatastore.delete(key)
      end
    end
    assert_equal(0, SimpleDatastore.keys.length)
    assert_equal('A', SimpleDatastore[:A] = 'A')
    assert_equal('B', SimpleDatastore[:B] = 'B')
    assert_equal('C', SimpleDatastore[:C] = 'C')
    assert_equal('D', SimpleDatastore[:D] = 'D')
    assert_equal('E', SimpleDatastore[:E] = 'E')
    assert_equal(5, SimpleDatastore.keys.length)
  end

  def test_2_get
    assert_equal(5, SimpleDatastore.keys.length)
    assert_equal('A', SimpleDatastore[:A])
    assert_equal('B', SimpleDatastore[:B])
    assert_equal('C', SimpleDatastore[:C])
    assert_equal('D', SimpleDatastore[:D])
    assert_equal('E', SimpleDatastore[:E])
  end
end
