class VirtManagerController < ApplicationController
  protect_from_forgery
  
  skip_before_filter :verify_authenticity_token
#  before_filter :cors_preflight_check
  #  after_filter :cors_set_access_control_headers
  after_filter :set_access_control_headers

  def set_access_control_headers
#    headers['Access-Control-Allow-Origin'] = '*'
#    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
#    headers['Access-Control-Allow-Headers'] = '*'
#    headers['Access-Control-Max-Age'] = '1728000' 
 end

  def all_list
    require "libvirt"
    conn = Libvirt::open("qemu:///system")
    vm_defined_domains_list = conn.list_defined_domains
    vm_defined_networks_list = conn.list_defined_networks
    vm_domains_list = conn.list_domains
    vm_networks_list = conn.list_networks


    vm_details_info = []

    vm_domains_list.each{|dom_id|
      vm = conn.lookup_domain_by_id(dom_id)
      vm_details_info.push({"name"=> vm.name, "max_vcpus"=> vm.max_vcpus, "state"=> vm.state, "max_memory"=> vm.max_memory,  "os_type"=> vm.os_type, "uuid"=> vm.uuid})
    }

    vm_defined_domains_list.each{|dom_name|
      vm = conn.lookup_domain_by_name(dom_name)
      vm_details_info.push({"name"=> vm.name, "max_vcpus"=> 0, "state"=> vm.state, "max_memory"=> vm.max_memory,  "os_type"=> vm.os_type, "uuid"=> vm.uuid})
    }

    nw_details_info = []

    vm_networks_list.each{|nw_name|
      nw = conn.lookup_network_by_name(nw_name)
      nw_details_info.push({"name" => nw.name, "uuid" => nw.uuid, "bridge" => nw.bridge_name, "xml_desc" => ERB::Util.html_escape(nw.xml_desc)})
    }


    return_list = {
      "defined_domains"=> vm_defined_domains_list,"defined_networks"=> vm_defined_networks_list,
      "domains"=> vm_domains_list, "networks"=> vm_networks_list,
      "vm_details_info"=> vm_details_info, "nw_details_info" => nw_details_info}
    render json: return_list, callback: params[:callback]
  end

  def startup
    target_vm = params[:target]
    require "libvirt"
    conn = Libvirt::open("qemu:///system")
    vm = conn.lookup_domain_by_name(target_vm)
    vm.create
    
    render json: {"state" => "success", "type" => "start"}, callback: params[:callback]
  end

  def shutdown
    target_vm = params[:target]
    require "libvirt"
    conn = Libvirt::open("qemu:///system")
    vm = conn.lookup_domain_by_name(target_vm)
    vm.destroy

    render json: {"state" => "success", "type" => "shutdown"}, callback: params[:callback]
  end

  def reboot
    render json: {"state" => "success", "type" => "reboot"}, callback: params[:callback]
  end

  def delete
    target_vm = params[:target]
    require "libvirt"
    conn = Libvirt::open("qemu:///system")
    vm = conn.lookup_domain_by_name(target_vm)
    vm.undefine

    render json: {"state" => "success", "type" => "shutdown"}, callback: params[:callback]

  end
end
