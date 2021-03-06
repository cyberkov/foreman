class CreatePtables < ActiveRecord::Migration
  class Ptable < ActiveRecord::Base; end
  def self.up
    create_table :ptables do |t|
      t.string :name,   :limit => 64, :null => false
      t.string :layout, :limit => 4096, :null => false
      t.references :operatingsystem
      t.timestamps
    end
    Ptable.create :name => "Kickstart default", :layout => <<EOF
#kind: ptable
#name: Community Kickstart Disklayout
#oses:
#- CentOS 5
#- CentOS 6
#- Fedora 16
#- Fedora 17
#- Fedora 18
#- Fedora 19
#- RedHat 5
#- RedHat 6
zerombr
clearpart --all --initlabel
autopart
EOF
    Ptable.create :name => "Preseed default", :layout => <<EOF
#kind: ptable
#name: Community Preseed Disklayout
#oses:
#- Debian 6.0
#- Debian 7.0
#- Ubuntu 10.04
#- Ubuntu 12.04
#- Ubuntu 13.04
<% if @host.params['install-disk'] -%>
d-i partman-auto/disk string <%= @host.params['install-disk'] %>
<% else -%>
d-i partman-auto/disk string /dev/sda /dev/vda
<% end -%>

### Partitioning
# The presently available methods are: "regular", "lvm" and "crypto"
<% if @host.params['partitioning-method'] -%>
d-i partman-auto/method string <%= @host.params['partitioning-method'] %>
<% else -%>
d-i partman-auto/method string regular
<% end -%>

# If one of the disks that are going to be automatically partitioned
# contains an old LVM configuration, the user will normally receive a
# warning. This can be preseeded away...
d-i partman-lvm/device_remove_lvm boolean true
# The same applies to pre-existing software RAID array:
d-i partman-md/device_remove_md boolean true
# And the same goes for the confirmation to write the lvm partitions.
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

<% if @host.params['partitioning-method'] && @host.params['partitioning-method'] == 'lvm' -%>
# For LVM partitioning, you can select how much of the volume group to use
# for logical volumes.
d-i partman-auto-lvm/guided_size string max
<% end -%>

# You can choose one of the three predefined partitioning recipes:
# - atomic: all files in one partition
# - home:   separate /home partition
# - multi:  separate /home, /usr, /var, and /tmp partitions
<% if @host.params['partitioning-recipe'] -%>
d-i partman-auto/choose_recipe select <%= @host.params['partitioning-recipe'] %>
<% else -%>
d-i partman-auto/choose_recipe select atomic
<% end -%>

# If you just want to change the default filesystem from ext3 to something
# else, you can do that without providing a full recipe.
<% if @host.params['partitioning-filesystem'] -%>
d-i partman/default_filesystem string <%= @host.params['partitioning-filesystem'] %>
<% end %>

# This makes partman automatically partition without confirmation, provided
# that you told it what to do using one of the methods above.
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF

    create_table :operatingsystems_ptables, :id => false do |t|
      t.references :ptable, :null => false
      t.references :operatingsystem, :null => false
    end

  end

  def self.down
    drop_table :ptables
    drop_table :operatingsystems_ptables
  end
end
