
describe Kontena::ServicePods::Terminator do

  let(:service_id) { 'service-id' }
  let(:subject) { described_class.new(service_id, 1) }

  describe '#perform' do
    it 'terminates service instance' do
      service_container = double(:service, :load_balanced? => false, :name => '/foo')
      allow(subject).to receive(:get_container).with(service_id, 1).and_return(service_container)
      allow(subject).to receive(:get_container).with(service_id, 1, 'volume')

      expect(service_container).to receive(:stop).with({'timeout' => 10})
      expect(service_container).to receive(:wait)
      expect(service_container).to receive(:delete).with({v: true})
      subject.perform
    end

    it 'removes volumes if exist' do
      service_container = spy(:service)
      service_container_volumes = double(:service, name: '/foo-1-volumes')
      allow(subject).to receive(:get_container).with(service_id, 1).and_return(service_container)
      allow(subject).to receive(:get_container).with(service_id, 1, 'volume').and_return(service_container_volumes)
      expect(service_container_volumes).to receive(:delete).with({v: true})
      subject.perform
    end

    it 'removes volumes if exist and service_container does not exist' do
      service_container_volumes = double(:service, name: '/foo-volumes')
      allow(subject).to receive(:get_container).with(service_id, 1).and_return(nil)
      allow(subject).to receive(:get_container).with(service_id, 1, 'volume').and_return(service_container_volumes)
      expect(service_container_volumes).to receive(:delete).with({v: true})
      subject.perform
    end
  end

  describe '#remove_from_load_balancer?' do
    it 'returns false by default' do
      service_container = spy(:service_container)
      expect(subject.remove_from_load_balancer?(service_container)).to be_falsey
    end

    it 'returns true if load balanced, first instance and options force lb cleanup' do
      subject = described_class.new(service_id, 1, {'lb' => true})
      service_container = spy(:service_container, :load_balanced? => true, :instance_number => 1)
      expect(subject.remove_from_load_balancer?(service_container)).to be_truthy
    end

    it 'returns false if load balanced, not a first instance and options force lb cleanup' do
      subject = described_class.new(service_id, {'lb' => true})
      service_container = spy(:service_container, :load_balanced? => true, :instance_number => 2)
      expect(subject.remove_from_load_balancer?(service_container)).to be_falsey
    end

    it 'returns false if load balanced, first instance' do
      service_container = spy(:service_container, :load_balanced? => true, :instance_number => 1)
      expect(subject.remove_from_load_balancer?(service_container)).to be_falsey
    end
  end
end
