require 'xa/rules/rule'

describe XA::Rules::Rule do
  context 'meta information' do
    it 'a rule should contain meta information about which tables and columns are required' do 
      r = XA::Rules::Rule.new
      expected = {
        'foo' => ['x', 'y'],
        'bar' => ['a', 'b'],
      }
      expected.each do |tn, cols|
        r.expects(tn, cols)
      end

      expect(r.meta.expects.length).to eql(expected.keys.length)
      actual = r.meta.expects.inject({}) do |o, ex|
        o.merge(ex.table => ex.columns)
      end

      expect(actual).to eql(expected)
    end
  end

  context 'execution' do
    it 'fails execution if expectations are not met' do
      r = XA::Rules::Rule.new

      res = r.execute({})
      expect(res).to_not be_nil
      expect(res.status).to eql(:ok)
      expect(res.failures).to be_empty

      r.expects('foo', ['a', 'b'])

      res = r.execute({})
      expect(res).to_not be_nil
      expect(res.status).to eql(:missing_expected_table)
      expect(res.failures).to_not be_empty
      expect(res.failures.first).to eql('foo')

      res = r.execute('foo' => [])
      expect(res).to_not be_nil
      expect(res.status).to eql(:ok)
      expect(res.failures).to be_empty
    end

    let(:tables) do
      {
        'foo' => [
          { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
          { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4 },
          { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 9 },
          { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
        ],
        'bar' => [
          { 'a' => 1, 'b' => 1, 'c' => 0 },
          { 'a' => 2, 'b' => 2, 'c' => 1 },
        ],
        'baz' => [
          { 'q' => 2, 'p' => 2, 'r' => 1 },
          { 'q' => 2, 'p' => 3, 'r' => 2 },
        ],
      }
    end

    it 'duplicates tables' do
      expected = ['foo', 'bar', 'baz', 'bar']
      expected.each do |n|
        r = XA::Rules::Rule.new
        r.push(n)
        r.duplicate
        r.store('a')
        r.store('b')
        r.commit(['a', 'b'])

        res = r.execute(tables.dup)
        expect(res.tables['a']).to eql(tables[n])
        expect(res.tables['b']).to eql(tables[n])
      end
    end
    
    it 'applies actions to a table' do
      expected = [
        {
          tables: ['foo', 'bar'],
          relation:  [['x', 'y'], ['a', 'b']],
          function: :join,
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 2, 'b' => 2, 'c' => 1 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 1, 'b' => 1, 'c' => 0 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['foo', 'bar'],
          relation:  [['x'], ['a']],
          function: :join,
          args: ['b'],
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1, 'b' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4, 'b' => 2 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 9, 'b' => 1 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['foo', 'baz'],
          relation:  [['x'], ['q']],
          function: :join,
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
              # row reproduced due to two matches in the joining table
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4, 'q' => 2, 'p' => 2, 'r' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 4, 'q' => 2, 'p' => 3, 'r' => 2},
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 9 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
        {
          tables: ['foo', 'bar'],
          relation: [['x'], ['b']],
          function: :replace,
          args: ['a', 'c'],
          final: {
            'output' => [
              { 'x' => 1, 'y' => 2, 'z' => 1, 'a' => 1 },
              { 'x' => 2, 'y' => 2, 'z' => 2, 'a' => 2 },
              { 'x' => 1, 'y' => 1, 'z' => 3, 'a' => 1 },
              { 'x' => 3, 'y' => 3, 'z' => 4, 'a' => 16 },
            ],
          },
        },
      ]

      expected.each do |ex|
        r = XA::Rules::Rule.new

        ex[:tables].each { |n| r.push(n) }
        
        r.apply(ex[:function], ex.fetch(:args, [])).using(*ex[:relation])
        r.store('output')
        r.commit(['output'])

        res = r.execute(tables.dup)
        expect(res.tables).to eql(ex[:final])
      end
    end
  end
end
