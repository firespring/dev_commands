module Dev
  module Workflow
    module SourceControl
      class Git < Base
        def initialize

          # Nothing to do here
        end















        def start(branch)
          checkout_all(branch)

    # 2.) Use gitflow to start the story branch (specify alt base branch)
    #run_command("#{SCRIPT_DIR}/.flow.story.start #{Story.name} #{ENV['ALT_BASE_BRANCH']}")


=begin
if [ `git ls-remote --heads --exit-code ${REMOTE_URL} story/${STORY_NAME} &>/dev/null; echo $?` -eq 0 ]
then
  set_yellow 2>/dev/null
  echo "Story [ ${STORY_NAME} ] already exists in the [ `pwd` ] project."
  reset_colors 2>/dev/null

  set_green 2>/dev/null
  echo "Checking out story ${STORY_NAME}"
  reset_colors 2>/dev/null
  git checkout "story/${STORY_NAME}"
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ checkout story/${STORY_NAME} ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  fi

else
  base_branch='master'
  if [ "$ALT_BASE_BRANCH" != '' ]
  then
    base_branch="$ALT_BASE_BRANCH"
  fi

  set_green 2>/dev/null
  echo "Checking out ${base_branch}"
  reset_colors 2>/dev/null
  git checkout ${base_branch}
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ checkout ${base_branch} ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  fi

  set_green 2>/dev/null
  echo "Pulling ${base_branch}"
  reset_colors 2>/dev/null
  git pull
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ ${base_branch} pull ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  fi

  set_green 2>/dev/null
  echo "Starting story ${STORY_NAME} off of ${base_branch}"
  reset_colors 2>/dev/null

  git checkout -b "story/${STORY_NAME}" "${base_branch}"
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [start story/${STORY_NAME} ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  fi

  git push -u origin "story/${STORY_NAME}"
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ publishing story/${STORY_NAME} ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  fi
fi

set_green 2>/dev/null
echo "Pulling ${STORY_NAME}"
reset_colors 2>/dev/null
git pull
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ story/${STORY_NAME} pull ]"
  reset_colors 2>/dev/null
  exit 1
fi

set_white 2>/dev/null
echo -e "----------------------------------------------------------------------------------------"
reset_colors 2>/dev/null
echo
=end


        end




















        def review
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
    # 4.) Merge base branch into the story branch to make sure it is up to date (try to honor alt base branch)

        base = ENV['ALT_BASE_BRANCH'] || 'master'
    puts
    run_command("#{SCRIPT_DIR}/.merge #{base} #{Story.branch}")
=begin
#!/bin/bash
. ~/.env.colors 2>/dev/null

SOURCE_BRANCH_NAME="$1"
DEST_BRANCH_NAME="$2"
if [ "${SOURCE_BRANCH_NAME}" == '' ] || [ "${DEST_BRANCH_NAME}" == '' ]
then
  echo -e "\n  `basename $0` SOURCE_BRANCH_NAME DEST_BRANCH_NAME\n"
  exit 1
fi

set_white 2>/dev/null
echo -e "----------------------------------------------------------------------------------------"

REMOTE_URL=`git config --get remote.origin.url`

if [ `git ls-remote --heads --exit-code ${REMOTE_URL} ${SOURCE_BRANCH_NAME} &>/dev/null; echo $?` -ne 0 ]
then
  set_yellow 2>/dev/null
  echo "Branch [ ${SOURCE_BRANCH_NAME} ] does not exist in the [ `pwd` ] project."
  set_white 2>/dev/null
  echo -e "----------------------------------------------------------------------------------------"
  reset_colors 2>/dev/null
  echo

  exit 0
fi

if [ `git ls-remote --heads --exit-code ${REMOTE_URL} ${DEST_BRANCH_NAME} &>/dev/null; echo $?` -ne 0 ]
then
  set_yellow 2>/dev/null
  echo "Branch [ ${DEST_BRANCH_NAME} ] does not exist in the [ `pwd` ] project."
  set_white 2>/dev/null
  echo -e "----------------------------------------------------------------------------------------"
  reset_colors 2>/dev/null
  echo

  exit 0
fi

LOCAL_CHANGES="`git status --porcelain | egrep -v "^\?" | awk '{print $2}'`"
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ git status ]"
  reset_colors 2>/dev/null
  exit 1
fi

# No changes allowed
if [ "${LOCAL_CHANGES}" != "" ]
then
  set_red 2>/dev/null
  echo "Local workspace is dirty. Please 'git add' them or 'git stash' them."
  reset_colors 2>/dev/null
  exit 1
fi

set_green 2>/dev/null
echo "Checking out ${SOURCE_BRANCH_NAME}"
reset_colors 2>/dev/null
git checkout ${SOURCE_BRANCH_NAME}
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ ${SOURCE_BRANCH_NAME} checkout ]. This will require your attention to resolve."
  reset_colors 2>/dev/null
  exit 1
fi

set_green 2>/dev/null
echo "Pulling ${SOURCE_BRANCH_NAME}"
reset_colors 2>/dev/null
git pull
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ ${SOURCE_BRANCH_NAME} pull ]. This will require your attention to resolve."
  reset_colors 2>/dev/null
  exit 1
fi

set_green 2>/dev/null
echo "Checking out ${DEST_BRANCH_NAME}"
reset_colors 2>/dev/null
git checkout ${DEST_BRANCH_NAME}
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ ${DEST_BRANCH_NAME} checkout ]. This will require your attention to resolve."
  reset_colors 2>/dev/null
  exit 1
fi

set_green 2>/dev/null
echo "Pulling ${DEST_BRANCH_NAME}"
reset_colors 2>/dev/null
git pull
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ ${DEST_BRANCH_NAME} pull ]. This will require your attention to resolve."
  reset_colors 2>/dev/null
  exit 1
fi

set_green 2>/dev/null
echo "Merging ${SOURCE_BRANCH_NAME} into ${DEST_BRANCH_NAME}"
reset_colors 2>/dev/null
git merge ${SOURCE_BRANCH_NAME}
if [ $? -ne 0 ]
then
  LOCAL_CONFLICTS="`git status --porcelain | egrep "^[DAU]{2}" | awk '{print $2}'`"
  if [ $? -ne 0 ]
  then
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ git status ]"
    reset_colors 2>/dev/null
    exit 1
  fi

  # If any of the conflicts are not a submodule, error.
  for changed_file in ${LOCAL_CONFLICTS}
  do
    set_red 2>/dev/null
    echo "Non-zero exit status detected during [ ${SOURCE_BRANCH_NAME} merge into ${DEST_BRANCH_NAME} ]. This will require your attention to resolve."
    reset_colors 2>/dev/null
    exit 1
  done

  set_yellow 2>/dev/null
  echo "Merge conflicts are all submodules. Attempting to fix automatically"
  reset_colors 2>/dev/null

fi

set_green 2>/dev/null
echo "Pushing ${DEST_BRANCH_NAME}"
reset_colors 2>/dev/null
git push
if [ $? -ne 0 ]
then
  set_red 2>/dev/null
  echo "Non-zero exit status detected during [ push to ${DEST_BRANCH_NAME} ]. This will require your attention to resolve."
  reset_colors 2>/dev/null
  exit 1
fi

set_white 2>/dev/null
echo -e "----------------------------------------------------------------------------------------"
reset_colors 2>/dev/null
echo
=end















        end




















        def delete
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?
    raise 'The only valid values for FORCE_DELETE are blank and "true"' if ENV['FORCE_DELETE'] && ENV['FORCE_DELETE'] != 'true'

    # 1.) Delete the git branch (with confirmation)
    message = "This will delete the ".light_green +
      "#{Story.branch} ".light_yellow +
      "branch".light_green
    with_confirmation(message) { run_command("FORCE_DELETE=#{ENV['FORCE_DELETE']} #{SCRIPT_DIR}/.flow.story.delete #{Story.name}") }
        end



















        def finish
    raise 'Unable to authenticate with GitHub. Check your credentials' unless GitHub.new.authenticated?

    %w[NO_SQUASH NO_CI NO_RELEASE_CLOSED NO_RELEASE_MATCH NO_BETA_REMOVE NO_PR].each do |x|
      raise "The only valid values for #{x} are blank or \"true\"" if ENV[x] && !ENV[x].casecmp?('true')
    end


    # 5.) Require the release already defined on the story, if exists, to match the release we're finishing into
    unless ENV["NO_RELEASE_MATCH"]
      story_data = TargetProcess::UserStory.find_by_Id(Story.number)

      unless story_data.release.nil?
        raise "#{Story.release_branch} does not match the assigned release/#{story_data.release["Name"]} on TargetProcess" if Story.release_name != story_data.release["Name"]
      end
    end

    # 6.) Merge the git branch in to the release
    message = "This will merge the ".light_green +
      "#{Story.branch} ".light_yellow +
      "branch into the ".light_green +
      "#{Story.release_branch} ".light_yellow +
      "branch and delete the ".light_green +
      "#{Story.branch} ".light_yellow +
      "branch".light_green
    with_confirmation(message) { run_command("#{SCRIPT_DIR}/.flow.story.finish #{Story.name} #{Story.release_name}", env: ENV) }

        end
      end
    end
  end
end

=begin


=end

=begin
# finish


=end
