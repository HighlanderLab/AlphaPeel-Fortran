!-----------------------------------------------------------------------------------------------------------------------
! The Roslin Institute, The University of Edinburgh - AlphaGenes Group
!-----------------------------------------------------------------------------------------------------------------------
!
! MODULE: AlphaMLPInputModule
!
!> @file        AlphaMLPInputModule.f90
!
! DESCRIPTION:
!> @brief       Module holding input parameters
!>
!> @details     This MODULE contains a class which contains all input parameters read in from a spec file.
!> It also contains the default container object for the spec file, defaultInput.
!
!> @author      David Wilson, david.wilson@roslin.ed.ac.uk
!
!> @date        Feb 07, 2016
!
!> @version     0.0.1 (alpha)
!
! REVISION HISTORY:
! 2016.11.07  DWilson - Initial Version
!
!-----------------------------------------------------------------------------------------------------------------------
 

 Module AlphaMLPInputModule


    use iso_fortran_env
    use ConstantModule, only : FILELENGTH
    use baseSpecFileModule


    type, extends(baseSpecFile) ::  AlphaMLPInput
 
        integer :: nGenotypedAnimals
        ! integer :: nSnp !Already in baseSpecFile
        character(len=FILELENGTH) :: inputFile
        integer :: startSnp
        integer :: endSnp
        integer :: nCycles
        logical :: isSequence
        character(len=FILELENGTH) :: sequenceFile, pedFile, runtype
        character(len=FILELENGTH) :: mapFile, segFile, prefix, basePrefix

        logical :: writeHaps, writeDosages, writeParams, binaryCallOutput

        real(kind=real64), dimension(:), allocatable :: thresholds

    end type AlphaMLPInput

    integer(KIND=1), allocatable, dimension(:,:) :: defaultInputGenotypes



    interface AlphaMLPInput

        module procedure initFromFile
        ! module procedure initFromParams
        module procedure initFromSnps
    end interface AlphaMLPInput
    contains

        !---------------------------------------------------------------------------
        !> @brief Constructor for AlphaMLP input based on passed in parameters
        !> @author  David Wilson david.wilson@roslin.ed.ac.uk
        !> @date    Febuary 08, 2016
        !> @return AlphaMLPInput of info for spec file
        !---------------------------------------------------------------------------
        ! function initFromParams(nGenotypedAnimals,nSnp,inputFile,outputFile,startSnp,endSnp) result(res)
        !     integer,intent(in) :: nGenotypedAnimals
        !     integer,intent(in) :: nSnp
        !     character(len=*),intent(in) :: inputFile
        !     character(len=*),intent(in) :: outputFile
        !     integer,intent(in) :: startSnp
        !     integer,intent(in) :: endSnp

        !     type(AlphaMLPInput) :: res


        !     res%nGenotypedAnimals = nGenotypedAnimals
        !     res%nsnp = nsnp
        !     res%inputFile = inputFile
        !     res%outputFile = outputFile
        !     res%startSnp = startSnp
        !     res%endSnp = endSnp



        ! end function initFromParams

                !---------------------------------------------------------------------------
        !> @brief Constructor for AlphaMLP input based on passed in parameters
        !> @author  David Wilson david.wilson@roslin.ed.ac.uk
        !> @date    Febuary 08, 2016
        !> @return AlphaMLPInput of info for spec file
        !---------------------------------------------------------------------------
        function initFromSnps(startSnp,endSnp, runtype,isSeq) result(res)

            integer,intent(in) :: startSnp
            integer,intent(in) :: endSnp

            type(AlphaMLPInput) :: res
            character(len=*), intent(in ) :: runType
            logical, intent(in) :: isSeq

            res%startSnp = startSnp
            res%endSnp = endSnp
             res%nGenotypedAnimals = 0
            res%nSnp = endSnp-startSnp +1
            
            res%runType = runtype !< should be single or multi

            res%isSequence = isSeq

            res%nCycles = 10

            res%mapFile = "No map"
            res%segFile = "No seg"

            res%writeDosages = .true.            
            res%writeHaps = .true.
            res%writeParams = .true.   
            res%binaryCallOutput = .false.         


        end function initFromSnps

        
                !---------------------------------------------------------------------------
        !> @brief Constructor for AlphaMLP input based on a file that will be read in
        !> @author  David Wilson david.wilson@roslin.ed.ac.uk
        !> @date    Febuary 08, 2016
        !> @return AlphaMLPInput of info for spec file
        !---------------------------------------------------------------------------
        function initFromFile(SpecFileIn) result(res)
            use AlphaHouseMod, only: parseToFirstWhitespace,splitLineIntoTwoParts,toLower

            character(len=*),optional, intent(in) :: SpecFileIn !< Spec file input
            character(len=FILELENGTH) :: SpecFile
            type(AlphaMLPInput) :: res
            integer :: unit,IOStatus
            character(len=300) :: first, line, tmp
            character(len=:), allocatable::tag
            character(len=300),dimension(:), allocatable :: second

            if (present(SpecFileIn)) then
                specFile = SpecFileIn
            else
                specFile = "AlphaPeelSpec.txt"
            endif

            ! init everything
            res%nGenotypedAnimals = 0
            res%nSnp = 0
            res%startSnp = -1
            res%endSnp = -1
            res%inputFile = "AlphaPeelGenotypes.txt"
            res%basePrefix = ""
            res%pedFile = "No Pedigree"
            res%runType = "multi"
            res%segFile = "No seg"
            res%isSequence = .false.
            res%sequenceFile = ""

            res%nCycles = 10

            res%mapFile = "No map"
            res%segFile = "No seg"
            !Plink stuff
            res%resultFolderPath = ""

            res%plinkinputfile = ""
            res%plinkBinary = ""

            res%writeDosages = .true.            
            res%writeHaps = .true.
            res%writeParams = .true.            
            res%binaryCallOutput = .false.         



            open(newunit=unit, file=SpecFile, action="read", status="old")
            IOStatus = 0
            READFILE: do while (IOStatus==0)
                read(unit,"(A)", IOStat=IOStatus)  line
                if (len_trim(line)==0) then
                    CYCLE
                end if

                call splitLineIntoTwoParts(trim(line), first, second)
                tag = parseToFirstWhitespace(first)
                if (first(1:1)=="=" .or. len(trim(line))==0) then
                    cycle
                else
                    select case(trim(tag))

                        case("nanis")
                            read(second(1),*) res%nGenotypedAnimals

                        case("nsnp")
                            read(second(1),*) res%nsnp

                        case("inputfilepath")
                            if (.not. allocated(second)) then
                                write(*, "(A,A)") "No input file specified. Using default filename: ", res%inputFile
                            else
                                write(res%inputFile, "(A)") trim(second(1))
                            end if

                        case("outputfilepath")
                            if (.not. allocated(second)) then
                                write(*, "(A,A)") "No output file specified. Using default filename: ", res%basePrefix
                            else
                                write(res%basePrefix, "(A)") trim(second(1))
                            end if
                        
                        case("pedigree")
                            write(res%pedFile, "(A)") trim(second(1))
                        
                        case("startsnp")
                            read(second(1),*) res%startsnp

                        case("endsnp")
                            read(second(1),*) res%endSnp

                        case("runtype")
                            write(res%runType, "(A)") trim(second(1))

                        case("usesequence")
                            read(second(1),*) tmp
                            if(tmp == "yes") res%isSequence = .true.

                        case("sequencefile")
                            read(second(1),*) res%sequenceFile

                        case("ncycles")
                            read(second(1),*) res%nCycles

                        case("mapfile")
                            write(res%mapFile, "(A)") trim(second(1))
                        case("segfile")
                            write(res%segFile, "(A)") trim(second(1))
                        case("callingthresholds")
                            allocate(res%thresholds(size(second)))
                            do i=1,size(second)
                                read(second(i),*) res%thresholds(i)
                        enddo


                        case("writedosages")
                            read(second(1),*) tmp
                            if(tmp == "no") res%writeDosages = .false.            
                        
                        case("writehaps")
                            read(second(1),*) tmp
                            if(tmp == "no") res%writeHaps = .false.
                        
                        case("writeparams")
                            read(second(1),*) tmp
                            if(tmp == "no") res%writeParams = .false.            

                        case("binarycalloutput")
                            read(second(1),*) tmp
                            if(tmp == "yes") res%binaryCallOutput = .true.            



                        case("plinkinputfile")
                            if (.not. allocated(second)) then
                                write(error_unit, "(A)") "error, Plinkinputfile allocated incorrectly"
                            else
                                if (size(second) < 2) then
                                    write(error_unit, "(A)") "error, Plinkinputfile allocated incorrectly"
                                else
                                    if (tolower(second(1)) == "binary") then
                                        res%plinkBinary = .true.
                                    else
                                        res%plinkBinary = .false.
                                    endif

                                    write(res%plinkinputfile, "(A)") second(2)
                                endif

                            end if


                        case default
                            write(*,"(A,A)") trim(tag), " is not valid for the AlphaMLP Spec File."
                            cycle
                    end select
                endif

                
            enddo READFILE
            
            !isSequence
            if(res%sequenceFile .ne. "") then
                print *, "Sequence file detected, running in sequence mode"
                res%isSequence = .true.
            endif
            !Start/endSnp
            if(res%startSnp == -1 .or. res%endSnp == -1) then
                print *, "No start or end snp given, running entire chromosome"
                res%startSnp = 1
                res%endSnp = res%nSnp 
            endif

        end function initFromFile


        subroutine readSegregationFile(inputParams, segregationEstimates, segregationOffset, mapIndexes, mapDistance, pedigree)
            use PedigreeModule
            use ConstantModule, only : IDLENGTH
            real(kind=real64), dimension(:,:,:), allocatable, intent(inout) :: segregationEstimates 
            integer, intent(inout) :: segregationOffset  
            real(kind=real64), dimension(:,:), allocatable :: tmpSegregation    
            integer, dimension(:, :), allocatable :: mapIndexes
            real(kind=real64), dimension(:), allocatable :: mapDistance
            type(PedigreeHolder) , intent(inout) :: pedigree

            integer :: i, unit, numLDSnps, firstLD, lastLD
            real(kind=real64) :: normalizationConstant
            type(AlphaMLPInput) :: inputParams
            character(len=IDLENGTH) :: seqid 


            if(inputParams%mapFile == "No map") then
                do i = 1, size(mapIndexes, 2)
                    mapIndexes(:, i) = i
                enddo
                mapDistance = 0
            else
                open(newunit=unit,FILE=trim(inputParams%mapFile),STATUS="old") !INPUT FILE
                do i = 1, size(mapIndexes, 2)
                    read(unit, *) mapIndexes(1,i), mapIndexes(2,i), mapDistance(i)
                    ! print *, mapIndexes(1,i), mapIndexes(2,i), mapDistance(i)
                enddo

            endif 
            numLDSnps = maxval(mapIndexes)
            firstLD = mapIndexes(1, inputParams%startsnp)
            lastLD = mapIndexes(2, inputParams%endsnp)
            segregationOffset = firstLD - 1 !this way if the first snp is 1, the offset is 0

            allocate(segregationEstimates(4, max(lastLD-firstLD + 1, 1) , pedigree%pedigreeSize))
            allocate(tmpSegregation(4, numLDSnps))

            close(unit)
            open(newunit=unit,FILE=trim(inputParams%segFile),STATUS="old") !INPUT FILE

            do i=1,pedigree%pedigreeSize
                read (unit,*) seqid, tmpSegregation(1,:)
                read (unit,*) seqid, tmpSegregation(2,:)
                read (unit,*) seqid, tmpSegregation(3,:)
                read (unit,*) seqid, tmpSegregation(4,:)

                tmpID = pedigree%dictionary%getValue(seqid)

                if (tmpID /= DICT_NULL) then
                    segregationEstimates(:,:,tmpID) = tmpSegregation(:, firstLD:lastLD)
                else
                    print *, "Unrecognized animal", seqid
                endif
            end do

            normalizationConstant = .000001
            segregationEstimates = (1-normalizationConstant) * segregationEstimates + normalizationConstant
            ! print *, "read finished"
            ! print *, "Seg dimension", size(segregationEstimates,1), size(segregationEstimates,2), size(segregationEstimates, 3)
            ! print *, "Snp Info:", firstLD, lastLD, segregationOffset



        end subroutine

        ! subroutine readSequence(input, pedigree, sequenceData)
        !     use PedigreeModule
        !     use ConstantModule, only : IDLENGTH,DICT_NULL

        !     type(AlphaMLPInput),intent(in) :: input
        !     type(PedigreeHolder) , intent(inout) :: pedigree
        !     ! type(Pedigreeholder), intent(inout) :: genotype
        !     integer(KIND=1), allocatable, dimension(:) :: tmp, ref, alt
        !     integer(KIND=1), allocatable, dimension(:,:) :: genoEst
        !     integer, allocatable, dimension(:,:,:) :: sequenceData
        !     integer :: unit, tmpID,i, j
        !     character(len=IDLENGTH) :: seqid !placeholder variables
        !     real(kind=real64) :: err, p, q, pf

        !     allocate(sequenceData(input%endSnp-input%startSnp+1, 2, input%nGenotypedAnimals))

        !     open(newunit=unit,FILE=trim(input%sequenceFile),STATUS="old") !INPUT FILE
        
        !     ! allocate(res(input%nGenotypedAnimals,input%endSnp-input%startSnp+1))
        !     allocate(ref(input%endSnp-input%startSnp+1))
        !     allocate(alt(input%endSnp-input%startSnp+1))
        !     allocate(genoEst(input%endSnp-input%startSnp+1, 3))
        !     allocate(tmp(input%endSnp-input%startSnp+1))

        !     err = 0.01
        !     p = log(err)
        !     q = log(1-err)
        !     pf = log(.5)

        !     ! tmp = 9
        !     sequenceData = 0
        !     do i=1,input%nGenotypedAnimals
        !         read (unit,*) seqid, ref(:)
        !         read (unit,*) seqid, alt(:)

        !         tmpID = pedigree%dictionary%getValue(seqid)
        !         print *, tmpID
        !         sequenceData(:, 1, tmpId) = ref(:)
        !         sequenceData(:, 2, tmpId) = alt(:)

        !         genoEst(:, 1) = p*ref + q*alt
        !         genoEst(:, 2) = pf*ref + pf*alt
        !         genoEst(:, 3) = q*ref + p*alt

        !         tmp = maxloc(genoEst, dim=2) - 1
        !         where(ref+alt < 15) tmp = 9

        !         if (tmpID /= DICT_NULL) then
        !             call pedigree%pedigree(tmpID)%setGenotypeArray(tmp)
        !         endif
        !     end do

        !     close(unit)
        ! end subroutine readSequence


end module AlphaMLPInputModule