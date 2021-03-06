//
//  CalendarVC.swift
//  ec-calendar
//
//  Created by Hugo on 18/2/2019.
//  Copyright © 2019 Hugo. All rights reserved.
//

import ReactiveCocoa
import UIKit
import EventKit

private let identifier = "Cell"
private let header = "header"

struct Month {
    var month: String
    var day: Int
}

class CalendarVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {
    var cv: UICollectionView!
    var header: MonthHeaderView!
    var ecDate: [ECDate]!

    var currMonth = 0
    

    var tableview: UITableView!
    
    var isDoubleSunday = true;
    var seletedDay: ECDay?
    
    var eventList: [ECEvent] = [];
    var selectedDayPath: IndexPath?;

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = UIColor.white;
        self.navigationController?.navigationBar.isTranslucent = false;


//        setCalendarMode(); //toggle double Sun or Sat mode
        
        let year: Int = Calendar.current.component(.year, from: Date());
        let month: Int = Calendar.current.component(.month, from: Date()) - 1; //calendar month follow index start from 0..
        let day: Int = Calendar.current.component(.day, from: Date());
        seletedDay = ECDay(year: year, month: month, day: day); //default selet today
        currMonth = month;
        
        initCalendarDataSource()
        initCollectionView()
        initTableView()
        
        //default retrive today events, if have
        eventList = Helper.localRetrieveEvents(key: "\(LocalDataKey.Event)-\(seletedDay!.idString())");
        tableview.reloadData();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        cv.reloadData();
        
    }
    
    func setCalendarMode() -> Void {
        let doubleSunday =  UIBarButtonItem(title: "DoubleSun",
                                            style: .plain,
                                            target: self,
                                            action: #selector(doubleSundayMode));
        
        let doubleSaturday =  UIBarButtonItem(title: "DoubleSat",
                                              style: .plain,
                                              target: self,
                                              action: #selector(doubleSaturdayMode))
        
        self.navigationItem.rightBarButtonItems = [doubleSaturday, doubleSunday];
        
    }
    
    @objc func doubleSundayMode() -> Void {
        isDoubleSunday = true;
        currMonth = 0;
        header.lblMonth.text = ecDate[currMonth].month;
        
        initCalendarDataSource();
        cv.reloadData();
    }
    
    @objc func doubleSaturdayMode() -> Void {
        isDoubleSunday = false;
        currMonth = 0;
        header.lblMonth.text = ecDate[currMonth].month;
        
        initCalendarDataSource();
        cv.reloadData();
    }
    
    
    func isLeapYear() -> Bool {
        let year:Int = Calendar.current.component(.year, from: Date());
        
        return (year % 100 != 0) && (year % 4 == 0) || (year % 400 == 0);
    }

    func initCalendarDataSource() {
        
        ecDate = [];
        var startWeekday = 1
        
        var marTotalDay = isLeapYear() ? 31 : 30; //ec calendar set march total for leap year instead of feb, feb awayls 29 total
        var augTotalDay = isLeapYear() ? 31 : 30; //double Sat mode
        
        if Helper.isDoubleSundayMode()
        {
            augTotalDay = 31;
        }
        else
        {
            marTotalDay = 31;
        }

        let monthDict = [
            (name:Helper.Localized(key: "calendar_jan"), days:31),
            (name:Helper.Localized(key: "calendar_feb"), days:29),
            (name:Helper.Localized(key: "calendar_mar"), days:marTotalDay),
            (name:Helper.Localized(key: "calendar_apr"), days:30),
            (name:Helper.Localized(key: "calendar_may"), days:31),
            (name:Helper.Localized(key: "calendar_jun"), days:30),
            (name:Helper.Localized(key: "calendar_jul"), days:31),
            (name:Helper.Localized(key: "calendar_aug"), days:augTotalDay),
            (name:Helper.Localized(key: "calendar_sep"), days:30),
            (name:Helper.Localized(key: "calendar_oct"), days:31),
            (name:Helper.Localized(key: "calendar_nov"), days:30),
            (name:Helper.Localized(key: "calendar_dec"), days:31)
        ];
        for month in monthDict {
            let myDate = ECDate(month: month.name, totalDay: month.days);
            
            if isDoubleSunday == false && month.name == Helper.Localized(key: "calendar_dec")
            {
                startWeekday = WeekDays.Fri.rawValue;
            }

            startWeekday = myDate.calculateWeekdays(lastWeekday: startWeekday);

            if isDoubleSunday
            {
                if myDate.day.last?.weekday == WeekDays.Sun.rawValue {
                    startWeekday = WeekDays.Sun.rawValue
                }
            }
            else
            {
                if myDate.day.last?.weekday == WeekDays.Sat.rawValue {
                    startWeekday = WeekDays.Sat.rawValue
                }
            }

            ecDate.append(myDate);

        }
    }

    func initCollectionView() {
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.itemSize = CGSize(width: 50, height: 50)
        flowlayout.minimumInteritemSpacing = 0 // horizontal line space between items
        flowlayout.headerReferenceSize = CGSize(width: view.frame.size.width, height: 40)
        

        cv = UICollectionView(frame: CGRect(x: 0,
                                            y: 0,
                                            width: self.view.frame.size.width,
                                            height: 400),
                              collectionViewLayout: flowlayout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.white
        cv.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        cv.allowsSelection = true;
        cv.allowsMultipleSelection = false;

        cv.register(DateCVCell.self, forCellWithReuseIdentifier: identifier)
        cv.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")

        header = MonthHeaderView(frame: CGRect(x: 0, y: 10, width: view.frame.size.width, height: 40))
        header.backgroundColor = UIColor.white
        header.layer.borderWidth = 1.0
        header.layer.borderColor = UIColor.lightText.cgColor
        header.lblMonth.text = ecDate[currMonth].month

        // click event
        header.left.reactive.controlEvents(UIControl.Event.touchUpInside).observeValues { _ in
            self.currMonth -= 1

            if self.currMonth < 0 {
                self.currMonth = 11
            }
            self.header.lblMonth.text = self.ecDate[self.currMonth].month
            self.cv.reloadData()
        }

        header.right.reactive.controlEvents(UIControl.Event.touchUpInside).observeValues { _ in
            self.currMonth += 1

            if self.currMonth > 11 {
                self.currMonth = 0
            }
            self.header.lblMonth.text = self.ecDate[self.currMonth].month
            self.cv.reloadData()
        }

        self.view.addSubview(header)
        self.view.addSubview(cv)
        
        header.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide);
            make.width.equalTo(self.view);
            make.height.equalTo(40);
        }

        cv.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom);
            make.width.equalTo(self.view);
            make.height.equalTo(400);
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ecDate[currMonth].day.count;
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! DateCVCell

        let today: Day = ecDate[currMonth].day[indexPath.row];
        
        let year = Calendar.current.component(.year, from: Date());
        cell.today = ECDay(year: year,month: currMonth,day: today.day);
        cell.today?.weekDay = today.weekday;
        
        cell.hightlightToday(events: eventList);
        let evnets = Helper.localRetrieveEvents(key: "\(LocalDataKey.Event)-\(cell.today?.idString() ?? "")");
        cell.today?.events = evnets;
        cell.eventMark();
        

        if today.day < 0 {
            cell.isHidden = true;
        }else {
            cell.lblDate.text = String(ecDate[currMonth].day[indexPath.row].day)
            cell.isHidden = false;
            
            if today.weekday == 7 {
                cell.highlighSunDay()
            }else {
                cell.lblDate.textColor = UIColor.black;
            }
        }
        

        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! DateCVCell
        seletedDay = cell.today;
        eventList = cell.today?.events ?? [];
        tableview.reloadData();
        
        selectedDayPath = indexPath;

    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (kind == UICollectionView.elementKindSectionHeader)
        {
            let header: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
            
            weekendTitleView(header: header);
            
            return header;
        }
        
        return UICollectionReusableView();
    }
    
    func weekendTitleView(header:UIView) {
        var sun, mon, tue, wed, thu, fri, sat: UILabel!;
        
        sun = UILabel();
        sun.text = Helper.Localized(key: "calendar_sun");
        sun.textColor = UIColor.red;
        sun.textAlignment = .center;
        
        
        mon = UILabel();
        mon.text = Helper.Localized(key: "calendar_mon");
        mon.textColor = UIColor.black;
        mon.textAlignment = .center;

        tue = UILabel();
        tue.text = Helper.Localized(key: "calendar_tue");
        tue.textColor = UIColor.black;
        tue.textAlignment = .center;

        
        wed = UILabel();
        wed.text = Helper.Localized(key: "calendar_wed");
        wed.textColor = UIColor.black;
        wed.textAlignment = .center;

        thu = UILabel();
        thu.text = Helper.Localized(key: "calendar_thu");
        thu.textColor = UIColor.black;
        thu.textAlignment = .center;

        fri = UILabel();
        fri.text = Helper.Localized(key: "calendar_fri");
        fri.textColor = UIColor.black;
        fri.textAlignment = .center;

        sat = UILabel();
        sat.text = Helper.Localized(key: "calendar_sat");
        sat.textColor = UIColor.black;
        sat.textAlignment = .center;

        header.addSubview(sun);
        header.addSubview(mon);
        header.addSubview(tue);
        header.addSubview(wed);
        header.addSubview(thu);
        header.addSubview(fri);
        header.addSubview(sat);
        
        let width = cv.frame.size.width - 20; //content inset of left (10), right (10);
        
        sun.snp.makeConstraints { (make) in
            make.top.left.equalTo(header);
            make.size.equalTo(CGSize(width: width/7, height: 30));
        }
        
        mon.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(sun.snp.right)
        }
        
        tue.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(mon.snp.right)
            
        }
        
        wed.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(tue.snp.right)
            
        }
        
        thu.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(wed.snp.right)
        }
        
        fri.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(thu.snp.right)
        }
        
        sat.snp.makeConstraints { (make) in
            make.top.size.equalTo(sun);
            make.left.equalTo(fri.snp.right);
        }
        
    }


    //MARK: - tableview datasource,delegate
    func initTableView() {
        tableview = UITableView(frame: CGRect(x: 0,
                                              y: cv.frame.origin.y,
                                              width: self.view.frame.size.width,
                                              height: self.view.frame.size.height - cv.frame.size.height),
                                style: .grouped)
        tableview.backgroundColor = UIColor.white;
        tableview.delegate = self;
        tableview.dataSource = self;
        

        self.view.addSubview(tableview)
        
        tableview.snp.makeConstraints { (make) in
            make.top.equalTo(cv.snp.bottom);
            make.width.bottom.equalTo(self.view);
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventList.count;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return seletedDay?.toString();
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 80;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView();
        
        let btn = UIButton(type: .custom);
        btn.setTitle(Helper.Localized(key: "event_add"), for: .normal);
        btn.setTitleColor(UIColor.white, for: .normal);
        
        btn.backgroundColor = UIColor(red:0.20, green:0.69, blue:0.79, alpha:1.0);
        btn.layer.cornerRadius = 15;
        btn.clipsToBounds = true;
        
        btn.reactive.controlEvents(.touchUpInside).observeValues { _ in
            self.navigationController?.pushViewController(DayVC(day: self.seletedDay!), animated: true)
        }
        
        footer.addSubview(btn);
        
        btn.snp.makeConstraints({ (make) in
            make.center.equalTo(footer);
            make.size.equalTo(CGSize(width: 150, height: 40));
        })
        
        return footer;
        
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell: EventTableViewCell! = tableview.dequeueReusableCell(withIdentifier: identifier) as? EventTableViewCell

        if cell == nil {
            cell = EventTableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.accessoryType = .detailButton
            cell.selectionStyle = .none;
        }
        
        let todayEvent = eventList[indexPath.row];
        cell.title?.text = "\(todayEvent.title) (\(todayEvent.remark))";
        cell.remark?.text = todayEvent.remark;
        cell.location.text = todayEvent.location;
        cell.eventTime.text = Helper.date2TimeString(date: todayEvent.startDate);
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        eventList.remove(at: indexPath.row);
        
        let key = "\(LocalDataKey.Event)-\(seletedDay!.idString())";
    
        //save event to local, key format: event-20190320
        Helper.localSaveEvents(data: eventList, key: key);
        
        if selectedDayPath != nil
        {
            cv.reloadItems(at: [selectedDayPath!]); //for update event list after deleted
        }

        tableView.reloadData();
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }


}
