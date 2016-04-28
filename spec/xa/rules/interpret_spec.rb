require 'xa/rules/interpret'
require 'xa/rules/rule'

describe XA::Rules::Interpret do
  let(:rule) do
    instance_double(XA::Rules::Rule)
  end

  include XA::Rules::Interpret

  def with_rule(o)
    expect(XA::Rules::Rule).to receive(:new).and_return(rule)
    yield
    interpret(o)
  end
  
  it 'will configure expects' do
    o = {
      'meta' => {
        'expects' => {
          'foo' => ['z', 'zz'],
          'bar' => ['a', 'b'],
        },
      },
    }

    with_rule(o) do
      o['meta']['expects'].each do |tn, cols|
        expect(rule).to receive(:expects).with(tn, cols)
      end
    end
  end

  it 'will configure commands' do
    o = {
      'commands' => [
        {
          'type'  => 'use',
          'table' => 'foo',
        },
        {
          'type'  => 'use',
          'table' => 'bar' ,
        },
        {
          'type'  => 'apply',
          'table' => 'foo',
          'args'  => {
            'left'  => ['a', 'b'],
            'right' => ['f', 'g'],
          },
        },
        {
          'type'  => 'apply',
          'table' => 'baz',
          'args'  => {
            'left'  => ['qq', 'pp'],
            'right' => ['zz', 'yy'],
          },
        },
      ],
    }

    with_rule(o) do
      o['commands'].each do |c|
        send("expect_#{c['type']}", c, rule)
      end
    end
  end

  def expect_use(c, r)
    expect(r).to receive(:use).with(c['table'])
  end

  def expect_apply(c, r)
    expect(r).to receive(:apply).with(c['table'], c['args']['left'], c['args']['right'])
  end
end